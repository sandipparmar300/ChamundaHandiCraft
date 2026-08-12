using System.Net.Http.Headers;
using System.Text;
using ChamundaHandicraft.Helper.Constants;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace ChamundaHandicraft.Helper.ApiService;

/// <summary>
/// Talks to the Ocelot gateway and nothing else. Never to the API directly, never to
/// a database.
///
/// Token handling differs by tier and is resolved from the current request:
///   Admin    — JWT held in session under <see cref="SessionKeys.AdminToken"/>
///   Customer — customer JWT in session, plus the guest cart cookie so an anonymous
///              cart survives until sign-in merges it (CX principle 11)
/// </summary>
public class ApiService : IApiService
{
    private readonly HttpClient _http;
    private readonly IHttpContextAccessor _context;
    private readonly ILogger<ApiService> _logger;

    private static readonly JsonSerializerSettings JsonSettings = new()
    {
        NullValueHandling = NullValueHandling.Ignore,
        DateTimeZoneHandling = DateTimeZoneHandling.Local
    };

    public ApiService(HttpClient http, IHttpContextAccessor context, ILogger<ApiService> logger)
    {
        _http = http;
        _context = context;
        _logger = logger;
    }

    public Task<ResponseViewModel<T>> GetAsync<T>(
        string endpoint, IDictionary<string, string?>? query = null, CancellationToken cancellationToken = default) =>
        SendAsync<T>(HttpMethod.Get, endpoint, null, query, cancellationToken);

    public Task<ResponseViewModel<T>> PostAsync<T>(
        string endpoint, object? payload = null, CancellationToken cancellationToken = default) =>
        SendAsync<T>(HttpMethod.Post, endpoint, payload, null, cancellationToken);

    public Task<ResponseViewModel<T>> PutAsync<T>(
        string endpoint, object? payload = null, CancellationToken cancellationToken = default) =>
        SendAsync<T>(HttpMethod.Put, endpoint, payload, null, cancellationToken);

    public Task<ResponseViewModel<T>> DeleteAsync<T>(
        string endpoint, IDictionary<string, string?>? query = null, CancellationToken cancellationToken = default) =>
        SendAsync<T>(HttpMethod.Delete, endpoint, null, query, cancellationToken);

    public async Task<ResponseViewModel<T>> UploadAsync<T>(
        string endpoint,
        Stream content,
        string fileName,
        string contentType,
        IDictionary<string, string?>? fields = null,
        CancellationToken cancellationToken = default)
    {
        using var form = new MultipartFormDataContent();
        var file = new StreamContent(content);
        file.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        form.Add(file, "file", fileName);

        if (fields is not null)
        {
            foreach (var field in fields.Where(f => f.Value is not null))
            {
                form.Add(new StringContent(field.Value!), field.Key);
            }
        }

        using var request = new HttpRequestMessage(HttpMethod.Post, endpoint) { Content = form };
        return await ExecuteAsync<T>(request, cancellationToken);
    }

    public async Task<(Stream Content, string ContentType, string FileName)?> DownloadAsync(
        string endpoint, IDictionary<string, string?>? query = null, CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, BuildUrl(endpoint, query));
        Authorise(request);

        try
        {
            var response = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Download {Endpoint} returned {Status}", endpoint, (int)response.StatusCode);
                return null;
            }

            var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            var type = response.Content.Headers.ContentType?.MediaType ?? "application/octet-stream";
            var name = response.Content.Headers.ContentDisposition?.FileNameStar
                       ?? response.Content.Headers.ContentDisposition?.FileName?.Trim('"')
                       ?? "download";

            return (stream, type, name);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Download {Endpoint} failed", endpoint);
            return null;
        }
    }

    private async Task<ResponseViewModel<T>> SendAsync<T>(
        HttpMethod method,
        string endpoint,
        object? payload,
        IDictionary<string, string?>? query,
        CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(method, BuildUrl(endpoint, query));

        if (payload is not null)
        {
            request.Content = new StringContent(
                JsonConvert.SerializeObject(payload, JsonSettings), Encoding.UTF8, "application/json");
        }

        return await ExecuteAsync<T>(request, cancellationToken);
    }

    private async Task<ResponseViewModel<T>> ExecuteAsync<T>(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Authorise(request);

        try
        {
            var response = await _http.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            // The API always returns the envelope, including on 4xx — so deserialise
            // first and only fall back when the body is not our shape (gateway down,
            // proxy error page, timeout).
            if (!string.IsNullOrWhiteSpace(body))
            {
                try
                {
                    var envelope = JsonConvert.DeserializeObject<ResponseViewModel<T>>(body);
                    if (envelope is not null)
                    {
                        return envelope;
                    }
                }
                catch (JsonException)
                {
                    _logger.LogWarning(
                        "Unrecognised response body from {Url} ({Status})",
                        request.RequestUri, (int)response.StatusCode);
                }
            }

            return ResponseViewModel<T>.Fail(
                MessageConstant.ServiceUnavailable,
                (ApiStatusCode)(int)response.StatusCode);
        }
        catch (TaskCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning("Request to {Url} timed out", request.RequestUri);
            return ResponseViewModel<T>.Fail(MessageConstant.RequestTimedOut, ApiStatusCode.ServerError);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Request to {Url} failed", request.RequestUri);
            return ResponseViewModel<T>.Fail(MessageConstant.ServiceUnavailable, ApiStatusCode.ServerError);
        }
    }

    /// <summary>
    /// Attaches whichever credentials the current request carries. An anonymous
    /// storefront visitor gets no bearer token but still gets a guest id, which is
    /// what keeps their cart alive across pages.
    /// </summary>
    private void Authorise(HttpRequestMessage request)
    {
        var http = _context.HttpContext;
        if (http is null)
        {
            return;
        }

        var token = http.Session.GetString(SessionKeys.AdminToken)
                    ?? http.Session.GetString(SessionKeys.CustomerToken);

        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        if (http.Request.Cookies.TryGetValue(SessionKeys.GuestTokenCookie, out var guest)
            && !string.IsNullOrEmpty(guest))
        {
            request.Headers.TryAddWithoutValidation(SessionKeys.GuestTokenHeader, guest);
        }

        // Carried through to the API log so a support ticket can be traced end to end.
        request.Headers.TryAddWithoutValidation("X-Correlation-Id", http.TraceIdentifier);
    }

    private static string BuildUrl(string endpoint, IDictionary<string, string?>? query)
    {
        if (query is null || query.Count == 0)
        {
            return endpoint;
        }

        var pairs = query
            .Where(q => !string.IsNullOrEmpty(q.Value))
            .Select(q => $"{Uri.EscapeDataString(q.Key)}={Uri.EscapeDataString(q.Value!)}");

        var queryString = string.Join("&", pairs);

        return string.IsNullOrEmpty(queryString) ? endpoint : $"{endpoint}?{queryString}";
    }
}
