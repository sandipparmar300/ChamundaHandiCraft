using ChamundaHandicraft.Helper.ViewModel.Admin;
using ChamundaHandicraft.Helper.ViewModel.Customer;

namespace ChamundaHandicraft.Helper.ViewModel.Customer;

/// <summary>
/// Combined payload for the Customer Homepage, synchronizing Admin-managed
/// Banners, Categories, Promotions/Offers, Testimonials, and Storefront Settings.
/// </summary>
public class HomeIndexViewModel
{
    public List<BannerViewModel> HeroBanners { get; set; } = new();
    public List<CategoryViewModel> FeaturedCategories { get; set; } = new();
    public FlashSaleOfferViewModel? FlashSaleOffer { get; set; }
    public List<ProductCardViewModel> FlashSaleProducts { get; set; } = new();
    public List<TestimonialGridItem> Testimonials { get; set; } = new();
    public StorefrontConfigViewModel Config { get; set; } = new();
    public List<ProductCardViewModel> NewArrivals { get; set; } = new();
    public List<ProductCardViewModel> Bestsellers { get; set; } = new();
    public List<ArtisanSummary> Artisans { get; set; } = new();
    public List<ArticleCardViewModel> Articles { get; set; } = new();
}
