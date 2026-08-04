const allowedImgExtensions = /(\.png|\.jpg|\.jpeg|\.svg|\.webp)$/i;
const allowedVideoExtensions = /(\.mp4|\.mov|\.wmv|\.avi|\.avchd|\.flv|\.f4v|\.swf|\.mkv|\.webm|\.mpeg2)$/i;
const phoneregx = /^(?:(?:(?:\+?234(?:\h1)?|01)\h*)?(?:\(\d{2}\)))(?:\W*\d{3})?\W*\d{5}(?!\d)/
//const phoneregx = /(?:(?:(?:\+?234(?:\h1)?|01)\h*)?(?:\(\d{2}\)|\d{3})|\d{4})(?:\W*\d{3})?\W*\d{4}(?!\d)/gm
var AddLanguageModelId = "AddLanguageModel";
const fileSizefor2MB = 2097152;
const showSuccessMessage = (message) => {
    showNotif(message, 1);
};

const showErrorMessage = (message) => {
    showNotif(message, 2);
};

//1 = success
//2 = error
//3 = warning
//4 = info
const showNotif = (notifMessage, notifType) => {

    toastr.options = {
        "closeButton": false,
        "debug": false,
        "newestOnTop": false,
        "progressBar": false,
        "positionClass": "toast-top-right",
        "preventDuplicates": false,
        "onclick": null,
        "showDuration": "300",
        "hideDuration": "1000",
        "timeOut": "5000",
        "extendedTimeOut": "1000",
        "showEasing": "swing",
        "hideEasing": "linear",
        "showMethod": "fadeIn",
        "hideMethod": "fadeOut"
    };

    switch (notifType) {
        case 1:
            toastr.success(notifMessage);
            break;
        case 2:
            toastr.error(notifMessage);
            break;
        case 3:
            toastr.warning(notifMessage);
            break;
        case 4:
            toastr.info(notifMessage);
            break;
        default:
            return;
    }
};

function allowPasteAlpha(evt) {
    var pasteData = (evt.clipboardData || window.clipboardData).getData('text');

    var regex = /^[A-Za-z ]+$/;

    if (!regex.test(pasteData)) {
        evt.preventDefault();   // Block paste if invalid
        return false;
    }
}

function allowPasteAlphaNumeric(evt) {
    let clipboardData = evt.clipboardData || window.clipboardData;

    if (!clipboardData) return; // Safety fallback

    let pasteData = clipboardData.getData("text");

    // Allow alphabets + numbers + space
    let regex = /^[A-Za-z0-9 ]+$/;

    if (!regex.test(pasteData)) {
        evt.preventDefault();   // Block paste
        return false;
    }

    return true;
}


function allowOnlyAlpha(e) {
    let Code = ('charCode' in e) ? e.charCode : e.keyCode;
    if (!(Code == 32) && // space
        !(code > 64 && code < 91) && // upper alpha (A-Z)
        !(code > 96 && code < 123)) { // lower alpha (a-z)
        e.preventDefault();
    }
}

function allowOnlyNumbers(e) {
    let code = ('charCode' in e) ? e.charCode : e.keyCode;
    if (!(code > 47 && code < 58)) { // 0-9
        e.preventDefault();
    }
}

function allowDecimalNumbers(e, input) {
    const Code = e.which || e.keyCode;

    // Allow control keys (Backspace, Tab, Delete, Arrows)
    if (
        Code === 8 ||  // Backspace
        Code === 9 ||  // Tab
        Code === 46 || // Delete
        (code >= 37 && code <= 40) // Arrow keys
    ) {
        return;
    }

    const char = String.fromCharCode(code);

    // Allow one dot (.) if not already present
    if (char === '.') {
        if (input.value.includes('.')) {
            e.preventDefault(); // prevent second dot
        }
        return;
    }

    // Allow only digits 0–9
    if (!/[0-9]/.test(char)) {
        e.preventDefault();
    }
}

function allowAlphaNumericExtended(e) {
    var Code = ('charCode' in e) ? e.charCode : e.keyCode;

    // Allow: space (internal only), 0-9, A-Z, a-z, Arabic letters, hyphen, dot, parentheses
    if (
        !(Code == 32) &&                       // space
        !(code >= 48 && code <= 57) &&         // digits 0-9
        !(code >= 65 && code <= 90) &&         // uppercase A-Z
        !(code >= 97 && code <= 122) &&        // lowercase a-z
        !(code >= 0x0600 && code <= 0x06FF) && // Arabic letters
        !(Code == 45) &&                       // hyphen -
        !(Code == 46) &&                       // dot .
        !(Code == 40) &&                       // open parenthesis (
        !(Code == 41)                          // close parenthesis )
    ) {
        e.preventDefault();
    }
}

function allowAlphaNumeric(e) {
    var Code = ('charCode' in e) ? e.charCode : e.keyCode;
    if (!(Code == 32) && // space
        !(code > 47 && code < 58) && // numeric (0-9)
        !(code > 64 && code < 91) && // upper alpha (A-Z)
        !(code > 96 && code < 123)) { // lower alpha (a-z)
        e.preventDefault();
    }
};

function allowAlphaNumericExtended(e) {
    var Code = ('charCode' in e) ? e.charCode : e.keyCode;

    // Allow: space, 0-9, A-Z, a-z, hyphen, comma, slash, dot
    if (
        !(Code == 32) &&                       // space
        !(code > 47 && code < 58) &&           // numbers 0-9
        !(code > 64 && code < 91) &&           // A-Z
        !(code > 96 && code < 123) &&          // a-z
        !(Code == 45) &&                       // hyphen -
        !(Code == 44) &&                       // comma ,
        !(Code == 47) &&                       // slash /
        !(Code == 46)                          // dot .
    ) {
        e.preventDefault();
    }
}



function validateIsNumber(event) {
    let charCode = (event.which) ? event.which : event.keyCode
    if (String.fromCharCode(charCode).match(/[^0-9]/g))
        return false;
    return true
};

function hasDecimalPlace(value, x) {
    let pointIndex = value.indexOf('.');
    return pointIndex >= 0 && pointIndex < value.length - x;
}

$('.price-field').keypress(function (e) {
    let character = String.fromCharCode(e.keyCode)
    let newValue = this.value + character;
    if (isNaN(newValue) || hasDecimalPlace(newValue, 3)) {
        e.preventDefault();
        return false;
    }
});



function removeClassStopScrolling() {
    $('body').removeClass('stop-scrolling');
}

function spaceNotAllowed(e, ctrl) {
    if (ctrl.value.length === 0 && e.which === 32) e.preventDefault();
}

const showLoader = () => {
    if (!$("body").hasClass("pageloader"))
        $("body").addClass("pageloader");
};

const hideLoader = () => {
    if ($("body").hasClass("pageloader"))
        $("body").removeClass("pageloader");
};

function showHidePassword(ctrl, textBoxId) {
    if ($(ctrl).hasClass("hide-password")) {
        $(ctrl).attr("src", "/assets/images/eye-show.svg");
        $(ctrl).removeClass("hide-password");
        $(`#${textBoxId}`).attr("type", "text");
    }
    else {
        $(ctrl).addClass("hide-password");
        $(ctrl).attr("src", "/assets/images/eye-hide.svg");
        $(`#${textBoxId}`).attr("type", "password");
    }
}

//const fnSelectMenu = (id) => {
//    $(`#${id}`).addClass("active");
//};

//const fnSelectSubMenu = (id) => {
//    $(`#${id}`).addClass("active");
//    $(`#${id}-parent`).addClass("active");
//    setTimeout(() => { $(`#${id}-parent`).trigger("click"); }, 50);
//};

const fnSelectMenu = (id) => {
    // Highlight main menu
    const $menu = $(`#${id}`);
    $menu.addClass("active");

    // If it has children, ensure it's open
    if ($menu.hasClass("has-children")) {
        $menu.addClass("open");
    }

    // Optionally scroll into view
    const sidebar = document.querySelector(".sidebar-menu-list");
    if (sidebar && $menu.length) {
        sidebar.scrollTo({
            top: $menu[0].offsetTop - 60,
            behavior: "smooth"
        });
    }
};

const fnSelectSubMenu = (id) => {
    const $sub = $(`#${id}`);
    $sub.addClass("active");

    // Find parent <li.has-children> and open it
    const $parent = $sub.closest(".has-children");
    $parent.addClass("open");

    // Also highlight parent link (optional)
    $parent.children("a.menu-name").addClass("active");

    // Scroll into view
    const sidebar = document.querySelector(".sidebar-menu-list");
    if (sidebar && $sub.length) {
        sidebar.scrollTo({
            top: $sub[0].offsetTop - 100,
            behavior: "smooth"
        });
    }
};

function subStringOfSring(strText, stringLength) {
    var strString = "";

    if (strText != null && strText != undefined) {
        if (strText.length > stringLength) {
            strString = strText.substring(0, stringLength) + '....';
        }
        else {
            strString = strText;
        }
        return strString;
    }
    return strString;
}

function filled() {
    $('.form-control').each(function () {
        if ($(this).val() !== '') {
            $(this).addClass('filled');
        } else {
            $(this).removeClass('filled');
        }
    });
}

function validateImage(input) {
    const file = input.files[0];
    const allowedExtensions = ['jpg', 'jpeg', 'png'];
    const previewId = input.getAttribute('data-preview');
    const preview = document.getElementById(previewId);

    if (file) {
        const fileExtension = file.name.split('.').pop().toLowerCase();

        if (allowedExtensions.includes(fileExtension)) {
            const reader = new FileReader();
            reader.onload = function (e) {
                preview.src = e.target.result;
            };
            reader.readAsDataURL(file);
        } else {
            toastr.error('Only .jpg, .jpeg, and .png image files are allowed.');
            input.value = "";
            preview.src = "/assets/images/default-profile.png";
        }
    } else {
        preview.src = "/assets/images/default-profile.png";
    }
}

function gblRemoveSpace() {
    $('.form-control').on({
        input: function () {
            if ($(this).val().startsWith(' ')) {
                $(this).val($(this).val().trimStart())
                return;
            }
        },
        blur: function () {
            if ($(this).val().endsWith(' ')) {
                $(this).val($(this).val().trim())
            }
        },
    });
}

function bindStartEndDateValidation(startSelector, endSelector) {
    const $startInput = $(startSelector);
    const $endInput = $(endSelector);

    // ✅ Set Start Date = System Local Date (not UTC)
    const today = new Date();
    const formattedToday = today.getFullYear() + '-' +
        String(today.getMonth() + 1).padStart(2, '0') + '-' +
        String(today.getDate()).padStart(2, '0');
    $startInput.val(formattedToday);

    // ✅ Set Expiry Date = Start Date + 1 day
    const expiryDate = new Date(today);
    expiryDate.setDate(expiryDate.getDate() + 1);
    const formattedExpiry = expiryDate.getFullYear() + '-' +
        String(expiryDate.getMonth() + 1).padStart(2, '0') + '-' +
        String(expiryDate.getDate()).padStart(2, '0');
    $endInput.val(formattedExpiry);

    // When Start Date changes
    $startInput.on('change', function () {
        const startDate = $startInput.val();
        const endDate = $endInput.val();

        // ✅ Automatically set End Date = Start Date + 1 day
        if (startDate) {
            const nextDay = new Date(startDate);
            nextDay.setDate(nextDay.getDate() + 1);
            const formattedNextDay = nextDay.getFullYear() + '-' +
                String(nextDay.getMonth() + 1).padStart(2, '0') + '-' +
                String(nextDay.getDate()).padStart(2, '0');
            $endInput.val(formattedNextDay);
        }

        $endInput.attr('min', startDate);
        clearValidation($startInput, $endInput);

        if (startDate && endDate && new Date(startDate) > new Date(endDate)) {
            showError($startInput, 'Start Date cannot be after End Date');
            $endInput.val('');
        }
    });
        
    // When End Date changes
    $endInput.on('change', function () {
        const startDate = $startInput.val();
        const endDate = $endInput.val();

        $startInput.attr('max', endDate);
        clearValidation($startInput, $endInput);

        if (startDate && endDate && new Date(endDate) < new Date(startDate)) {
            showError($endInput, 'End Date cannot be before Start Date');
            $startInput.val('');
        }
    });

    function showError($element, message) {
        $element.next('.error-msg').text(message);
    }

    function clearValidation($el1, $el2) {
        $el1.next('.error-msg').text('');
        $el2.next('.error-msg').text('');
    }
}



const flagMap = {
    "+968": "om",
    "+963": "sy"
};
function updateFlag(value) {
    const flagCode = flagMap[value] || "om";
    $(".country-flag").attr("src", `https://flagcdn.com/w40/${flagCode}.png`);
}

const initialValue = $(".country-select").val();
updateFlag(initialValue);

$("#CountryCode").on("change", function () {
    updateFlag($(this).val());
});

function saveCountryToSession(country) {
    $.ajax({
        type: 'POST',
        url: '/Auth/SetCountry', // Adjust to your controller
        data: { country: country },
        success: function (response) {
            if (response.success) {
                console.log("Country stored in session: " + country);
            }
        },
        error: function () {
            console.log("Failed to save country in session.");
        }
    });
}

//function gblRemoveSpace() {
//    $('.form-control').on({
//        input: function () {
//            if ($(this).val().startsWith(' ')) {
//                $(this).val($(this).val().trimStart())
//                return;
//            }
//        },
//        blur: function () {
//            if ($(this).val().endsWith(' ')) {
//                $(this).val($(this).val().trim())
//            }
//        },
//    });
//}

function gblRemoveSpace() {
    $('input, textarea').on({
        input: function () {
            let value = $(this).val();

            // ❌ Prevent first character as space
            if (value.startsWith(' ')) {
                $(this).val(value.trimStart());
                return;
            }
        },
        blur: function () {
            let value = $(this).val();

            // ❌ Remove trailing spaces on blur
            if (value.endsWith(' ')) {
                $(this).val(value.trim());
            }
        }
    });

    $('.validAlphabet').on('input', function () {
        this.value = this.value.replace(/[^a-zA-Z ]/g, '');
    });
}

$("#CountryId").on("change", function () {
    const selectedOption = $(this).find("option:selected");
    if (!selectedOption || !selectedOption.val()) return;

    const countryText = selectedOption.text();   // The visible text
    //saveCountryToSession(countryText);
    localStorage.setItem("SelectedCountry", countryText); // ✅ store text
});

// Register custom client-side validation rule for HeaderRequiredIf
$.validator.addMethod("headerrequiredif", function (value, element, param) {
    const requiredCountry = param; // from data-val-headerrequiredif-country
    const currentCountry = window.selectedCountry || localStorage.getItem("SelectedCountry") || "Oman";

    // if current country matches the required one, then field must be filled
    if (currentCountry.toLowerCase() === requiredCountry.toLowerCase()) {
        return value && value.trim().length > 0;
    }

    // otherwise, validation passes
    return true;
});

// Link the method to the unobtrusive adapter
$.validator.unobtrusive.adapters.addSingleVal("headerrequiredif", "country");