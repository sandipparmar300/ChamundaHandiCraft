using System.Data;
using ChamundaHandicraft.Helper.Enums;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using Dapper;
using Microsoft.Data.SqlClient;
using Support.Domain.IServices;

namespace Support.Infrastructure.Repositories;

public class SupportRepository : ISupportRepository
{
    private readonly string _connectionString;

    public SupportRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    private SqlConnection CreateConnection() => new(_connectionString);

    public async Task<PagedResult<SupportTicketGridItem>> GetGridAsync(DataTableRequest request, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@SearchText", request.Search);
        parameters.Add("@SortColumn", string.IsNullOrWhiteSpace(request.SortBy) ? "CreatedAt" : request.SortBy);
        parameters.Add("@SortOrder", request.SortDescending ? "DESC" : "ASC");
        parameters.Add("@PageSize", request.PageSize <= 0 ? 25 : request.PageSize);
        parameters.Add("@PageIndex", request.Page <= 0 ? 1 : request.Page);
        parameters.Add("@TotalRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@TotalFilteredRecords", dbType: DbType.Int32, direction: ParameterDirection.Output);

        var rawItems = (await connection.QueryAsync<dynamic>(
            "dbo.usp_SupportTicket_GridList",
            parameters,
            commandType: CommandType.StoredProcedure)).AsList();

        var items = rawItems.Select(d => new SupportTicketGridItem
        {
            Id = d.Id,
            TicketNumber = d.TicketNumber ?? "",
            Subject = d.Subject ?? "",
            Topic = d.Topic ?? "General Query",
            CustomerName = d.CustomerName ?? "",
            RequesterEmail = d.RequesterEmail,
            RequesterPhone = d.RequesterPhone,
            OrderNumber = d.OrderNumber,
            Status = (TicketStatus)(int)d.Status,
            Priority = d.Priority ?? "Normal",
            AssignedTo = d.AssignedTo,
            OpenedOn = d.OpenedOn ?? DateTime.UtcNow,
            LastReplyOn = d.LastReplyOn,
            MessageCount = d.MessageCount ?? 1,
            CreatedOn = d.CreatedAt ?? DateTime.UtcNow
        }).ToList();

        var totalFiltered = parameters.Get<int>("@TotalFilteredRecords");
        return new PagedResult<SupportTicketGridItem>(items, totalFiltered, request.Page <= 0 ? 1 : request.Page, request.PageSize <= 0 ? 25 : request.PageSize);
    }

    public async Task<SupportTicketGridItem?> GetByIdAsync(int id, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var data = await connection.QueryFirstOrDefaultAsync<dynamic>(
            "dbo.usp_SupportTicket_GetById",
            new { Id = id },
            commandType: CommandType.StoredProcedure);

        if (data == null) return null;

        return new SupportTicketGridItem
        {
            Id = data.Id,
            TicketNumber = data.TicketNumber ?? "",
            Subject = data.Subject ?? "",
            Topic = data.Topic ?? "General Query",
            CustomerName = data.CustomerName ?? "",
            RequesterEmail = data.RequesterEmail,
            RequesterPhone = data.RequesterPhone,
            Description = data.Description,
            OrderNumber = data.OrderNumber,
            Status = (TicketStatus)(int)data.Status,
            Priority = data.Priority ?? "Normal",
            AssignedTo = data.AssignedTo,
            OpenedOn = data.OpenedOn ?? DateTime.UtcNow,
            LastReplyOn = data.LastReplyOn,
            MessageCount = data.MessageCount ?? 1,
            CreatedOn = data.CreatedAt ?? DateTime.UtcNow
        };
    }

    public async Task<int> SaveAsync(SupportTicketGridItem request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@TicketNumber", request.TicketNumber);
        parameters.Add("@CustomerName", request.CustomerName);
        parameters.Add("@RequesterName", request.CustomerName);
        parameters.Add("@RequesterEmail", request.RequesterEmail);
        parameters.Add("@RequesterPhone", request.RequesterPhone);
        parameters.Add("@Subject", request.Subject);
        parameters.Add("@Topic", request.Topic);
        parameters.Add("@Description", request.Description);
        parameters.Add("@Status", (int)request.Status);
        parameters.Add("@Priority", request.Priority);
        parameters.Add("@AssignedTo", request.AssignedTo);
        parameters.Add("@OrderNumber", request.OrderNumber);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@NewId", dbType: DbType.Int32, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_SupportTicket_Save", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<int>("@NewId");
    }

    public async Task<bool> DeleteAsync(int id, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", id);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_SupportTicket_Delete", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }

    public async Task<bool> UpdateStatusAsync(UpdateStatusRequest request, int? adminUserId = null, CancellationToken ct = default)
    {
        using var connection = CreateConnection();
        var parameters = new DynamicParameters();
        parameters.Add("@Id", request.Id);
        parameters.Add("@IsActive", request.IsActive);
        parameters.Add("@LoggedInUserId", adminUserId);
        parameters.Add("@Success", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        parameters.Add("@ErrorMessage", dbType: DbType.String, size: 500, direction: ParameterDirection.Output);

        await connection.ExecuteAsync("dbo.usp_SupportTicket_UpdateStatus", parameters, commandType: CommandType.StoredProcedure);

        var errorMessage = parameters.Get<string?>("@ErrorMessage");
        if (!string.IsNullOrWhiteSpace(errorMessage))
        {
            throw new InvalidOperationException(errorMessage);
        }

        return parameters.Get<bool>("@Success");
    }
}
