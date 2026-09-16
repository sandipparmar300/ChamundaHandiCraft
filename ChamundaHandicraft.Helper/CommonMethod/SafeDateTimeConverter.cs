using System.Text.Json;
using System.Text.Json.Serialization;

namespace ChamundaHandicraft.Helper.CommonMethod;

/// <summary>
/// Resilient DateTime converter for System.Text.Json.
/// Prevents DateTime deserialization failures from edge-case ISO formats or timezone conversions.
/// </summary>
public class SafeDateTimeConverter : JsonConverter<DateTime>
{
    public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.String)
        {
            var str = reader.GetString();
            if (string.IsNullOrWhiteSpace(str)) return DateTime.UtcNow;

            if (DateTime.TryParse(str, out var dt))
            {
                return dt;
            }

            if (DateTimeOffset.TryParse(str, out var dto))
            {
                return dto.UtcDateTime;
            }

            return DateTime.UtcNow;
        }

        if (reader.TokenType == JsonTokenType.Null)
        {
            return DateTime.UtcNow;
        }

        return DateTime.UtcNow;
    }

    public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToString("o"));
    }
}

/// <summary>
/// Resilient Nullable DateTime converter for System.Text.Json.
/// </summary>
public class SafeNullableDateTimeConverter : JsonConverter<DateTime?>
{
    public override DateTime? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null) return null;

        if (reader.TokenType == JsonTokenType.String)
        {
            var str = reader.GetString();
            if (string.IsNullOrWhiteSpace(str)) return null;

            if (DateTime.TryParse(str, out var dt)) return dt;
            if (DateTimeOffset.TryParse(str, out var dto)) return dto.UtcDateTime;

            return DateTime.UtcNow;
        }

        return null;
    }

    public override void Write(Utf8JsonWriter writer, DateTime? value, JsonSerializerOptions options)
    {
        if (value.HasValue)
            writer.WriteStringValue(value.Value.ToString("o"));
        else
            writer.WriteNullValue();
    }
}
