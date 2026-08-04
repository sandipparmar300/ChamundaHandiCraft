using Microsoft.AspNetCore.Mvc;

namespace ChamundaHandicraft.Admin.Controllers;

/// <summary>
/// View shell for the Auth screens. Each action renders markup only —
/// the ApiService calls and view models arrive with the API wiring.
/// </summary>
public class AuthController : Controller
{
    public IActionResult Login() => View();

    public IActionResult ForgotPassword() => View();

    public IActionResult ResetPassword() => View();

    public IActionResult Logout() => RedirectToAction(nameof(Login));
}

