using ChamundaHandicraft.Admin.Services;
using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Common;
using ChamundaHandicraft.Helper.ViewModel.Customer;
using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>Messages from the storefront contact form. Read-only — these records are created by the system, not an operator.</summary>
public class ContactSubmissionController : AdminListController<ContactSubmissionGridItem>
{
    public ContactSubmissionController(IAdminClient client) : base(client) { }

    protected override string Module => "ContactSubmission";
}
