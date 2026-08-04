$(document).ready(function () {

    // input fill

    $('.form-control').each(function () {
        if ($(this).val() !== '') {
            $(this).addClass('filled');
        }

        $(this).on('input', function () {
            if ($(this).val() !== '') {
                $(this).addClass('filled');
            } else {
                $(this).removeClass('filled');
            }
        });

        $(this).on('focus', function () {
            $(this).addClass('filled');
        });

        $(this).on('blur', function () {
            if ($(this).val() === '') {
                $(this).removeClass('filled');
            }
        });
    });

    // sidebar toggle


    var width = $(window).width();
    if (width < 768) {
        $(".sidebar-toggle-btn").click(function () {
            $(".dashboard-wrap").addClass("full-size");
        });
        $(".close-sidebar").click(function () {
            if ($("#mainDashboardWrap").hasClass("full-size")) {
                $("#mainDashboardWrap").removeClass("full-size");
            }
        });
    }
    if (width > 767) {
        $(".sidebar-toggle-btn").click(function () {
            $(".dashboard-wrap").toggleClass("full-size");
        });
    }

    $('.custom-select').selectpicker();

    new DataTable('.listing-order-table', {

        // responsive: true,
        lengthChange: false,
        searching: false,
        // scrollX: true,
        language: {
            'paginate': {
                'previous': '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="12" viewBox="0 0 7 12" fill="none"><path opacity="0.8" d="M6.057 1.12452e-08L0.4 5.656L6.057 11.313L7 10.37L2.285 5.656L7 0.942L6.057 1.12452e-08Z" fill="#1D1E31"/></svg>',
                'next': '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="12" viewBox="0 0 7 12" fill="none"><path d="M0.943 12L6.6 6.344L0.943 0.687L-4.53287e-07 1.63L4.715 6.344L-4.11761e-08 11.058L0.943 12Z" fill="#1D1E31"/></svg>'
            }
        },
        "initComplete": function (settings, json) {
            $(".listing-order-table").wrap("<div class='tb-responsive'></div>");
        },
    });

    new DataTable('#dsOrderList', {

        // responsive: true,
        lengthChange: false,
        searching: false,
        // scrollX: true,
        language: {
            'paginate': {
                'previous': '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="12" viewBox="0 0 7 12" fill="none"><path opacity="0.8" d="M6.057 1.12452e-08L0.4 5.656L6.057 11.313L7 10.37L2.285 5.656L7 0.942L6.057 1.12452e-08Z" fill="#1D1E31"/></svg>',
                'next': '<svg xmlns="http://www.w3.org/2000/svg" width="7" height="12" viewBox="0 0 7 12" fill="none"><path d="M0.943 12L6.6 6.344L0.943 0.687L-4.53287e-07 1.63L4.715 6.344L-4.11761e-08 11.058L0.943 12Z" fill="#1D1E31"/></svg>'
            }
        },
        "initComplete": function (settings, json) {
            $("#dsOrderList").wrap("<div class='tb-responsive'></div>");
        },
    });


    $(document).on("click", ".latest-orders-dropdown .dropdown-toggle", function () {
        const rowCount = datatable.rows({ filter: 'applied' }).count();
        if (rowCount === 1) {
            $(".dt-scroll-body").css("overflow", "visible");
        } else {
            $(".dt-scroll-body").css("overflow", "auto"); // keep visible for menu
        }
    });

});

