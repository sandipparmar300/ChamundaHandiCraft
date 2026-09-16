namespace Identity.Domain.Entities;

/// <summary>
/// Admin role definition. Maps 1:1 to dbo.Roles.
/// </summary>
public class Role
{
    public int Id { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string RoleKey { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsSystem { get; set; }
    public bool RequiresTwoFactor { get; set; }
    public int SortOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
}

public class UserRoleItem
{
    public int RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string RoleKey { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
}
