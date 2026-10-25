using System.Data;
using System.Globalization;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Dapper;
using Microsoft.Data.SqlClient;
using Settings.Domain.IServices;

namespace Settings.Infrastructure.Repositories;

public class SettingsRepository : ISettingsRepository
{
    private readonly string _connectionString;

    public SettingsRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<StorefrontConfigViewModel> GetStorefrontConfigAsync(CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var rows = (await connection.QueryAsync<(string Section, string SettingKey, string? SettingValue)>(
            "dbo.usp_Settings_GetStorefrontConfig",
            commandType: CommandType.StoredProcedure)).ToList();

        var dict = rows.ToDictionary(r => $"{r.Section}:{r.SettingKey}", r => r.SettingValue ?? "", StringComparer.OrdinalIgnoreCase);

        var config = new StorefrontConfigViewModel();

        if (dict.TryGetValue("shipping:FreeShippingThreshold", out var fst) && decimal.TryParse(fst, NumberStyles.Any, CultureInfo.InvariantCulture, out var fstVal))
            config.FreeShippingThreshold = fstVal;

        if (dict.TryGetValue("shipping:DefaultShippingCharge", out var sc) && decimal.TryParse(sc, NumberStyles.Any, CultureInfo.InvariantCulture, out var scVal))
            config.StandardShippingCost = scVal;

        if (dict.TryGetValue("contact:SupportPhone", out var phone) && !string.IsNullOrWhiteSpace(phone))
            config.SupportPhone = phone;
        else
            config.SupportPhone = "+91 98765 43210";

        if (dict.TryGetValue("contact:SupportEmail", out var email) && !string.IsNullOrWhiteSpace(email))
            config.SupportEmail = email;
        else
            config.SupportEmail = "support@chamundahandicraft.com";

        if (dict.TryGetValue("contact:WhatsAppNumber", out var wa) && !string.IsNullOrWhiteSpace(wa))
            config.SupportWhatsApp = wa;
        else
            config.SupportWhatsApp = "919876543210";

        if (dict.TryGetValue("contact:BusinessHours", out var hours) && !string.IsNullOrWhiteSpace(hours))
            config.SupportHours = hours;
        else
            config.SupportHours = "Mon–Sat, 10am–7pm IST";

        if (dict.TryGetValue("storefront:DefaultCurrency", out var curr) && !string.IsNullOrWhiteSpace(curr))
            config.CurrencyCode = curr;

        if (dict.TryGetValue("tax:CompanyGstin", out var gstin) && !string.IsNullOrWhiteSpace(gstin))
            config.Gstin = gstin;
        else
            config.Gstin = "08AABCK1234M1Z5";

        if (dict.TryGetValue("storefront:SiteName", out var siteName) && !string.IsNullOrWhiteSpace(siteName))
            config.LegalName = $"{siteName} Pvt. Ltd.";
        else
            config.LegalName = "Chamunda Handicraft Pvt. Ltd.";

        return config;
    }
}
