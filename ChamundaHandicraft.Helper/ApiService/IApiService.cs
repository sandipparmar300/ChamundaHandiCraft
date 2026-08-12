using ChamundaHandicraft.Helper.ViewModel.Common;

namespace ChamundaHandicraft.Helper.ApiService;

/// <summary>
/// The only way the Admin panel and the Customer site reach the gateway. Both tiers
/// inject this; neither constructs an <c>HttpClient</c> or a URL of its own.
///
/// Pass a constant from <see cref="Constants.ApiEndPoint"/> as <c>endpoint</c>. The
/// implementation attaches the base address, the bearer token (Admin) or the customer
/// and guest tokens (Customer), and unwraps the <see cref="ResponseViewModel{T}"/>
/// envelope — including on a non-2xx response, so callers never branch on status codes.
/// </summary>
public interface IApiService
{
    Task<ResponseViewModel<T>> GetAsync<T>(
        string endpoint,
        IDictionary<string, string?>? query = null,
        CancellationToken cancellationToken = default);

    Task<ResponseViewModel<T>> PostAsync<T>(
        string endpoint,
        object? payload = null,
        CancellationToken cancellationToken = default);

    Task<ResponseViewModel<T>> PutAsync<T>(
        string endpoint,
        object? payload = null,
        CancellationToken cancellationToken = default);

    Task<ResponseViewModel<T>> DeleteAsync<T>(
        string endpoint,
        IDictionary<string, string?>? query = null,
        CancellationToken cancellationToken = default);

    /// <summary>Multipart upload for product media, review photos and return evidence.</summary>
    Task<ResponseViewModel<T>> UploadAsync<T>(
        string endpoint,
        Stream content,
        string fileName,
        string contentType,
        IDictionary<string, string?>? fields = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Invoice PDFs and report exports, where the response is a file rather than JSON.
    /// Returns null when the API responds with anything but a 2xx.
    /// </summary>
    Task<(Stream Content, string ContentType, string FileName)?> DownloadAsync(
        string endpoint,
        IDictionary<string, string?>? query = null,
        CancellationToken cancellationToken = default);
}
