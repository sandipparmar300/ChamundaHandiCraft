window.DropdownHelper = (function () {

    $('.custom-select').attr('data-live-search', 'true');


    //function resetDropdown(selector, defaultText = "Select") {
    //    $(selector).empty().append(`<option value="">${defaultText}</option>`);
    //    $(selector).selectpicker('refresh');
    //}

    function resetDropdown(selector) {
        // Bootstrap 5 does NOT need selectpicker
        $(selector).trigger('change');
    }


    function bindDropdown({ url, paramKey, paramValue, targetSelector, defaultText = "Select", selectedId = null }) {
        resetDropdown(targetSelector, defaultText);

        if (!paramValue) return;

        $.get(url, { [paramKey]: paramValue }, function (data) {
            if (data.success) {
                const $dropdown = $(targetSelector);
                $dropdown.empty();
                $dropdown.append(`<option value="">` + defaultText + `</option>`);

                $.each(data.data, function (i, item) {
                    $dropdown.append(`<option value="${item.id}" ${selectedId == item.id ? 'selected' : ''}>${item.name}</option>`);
                });

                $dropdown.selectpicker('refresh');
            }
        });
    }

    function bindCascadingDropdowns(options) {
        const {
            countrySelector = options.countrySelector,
            stateSelector = options.stateSelector,
            citySelector = options.citySelector,
           
            endpoints,
            selectedValues = {}
        } = options;

        $(document).on('change', countrySelector, function () {
            const countryId = $(this).val();
            resetDropdown(stateSelector, "Select State");
            resetDropdown(citySelector, "Select City");
           

            bindDropdown({
                url: endpoints.state,
                paramKey: 'countryId',
                paramValue: countryId,
                targetSelector: stateSelector,
                defaultText: 'Select State'
            });
        });

        $(document).on('change', stateSelector, function () {
            const stateId = $(this).val();
            resetDropdown(citySelector, "Select City");
          

            bindDropdown({
                url: endpoints.city,
                paramKey: 'stateId',
                paramValue: stateId,
                targetSelector: citySelector,
                defaultText: 'Select City'
            });
        });

        $(document).on('change', citySelector, function () {
            const cityId = $(this).val();
          

            bindDropdown({
                url: endpoints.area,
                paramKey: 'cityId',
                paramValue: cityId,
                targetSelector: areaSelector,
               
            });
        });

        if (selectedValues.countryId) {
            bindDropdown({
                url: endpoints.state,
                paramKey: 'countryId',
                paramValue: selectedValues.countryId,
                targetSelector: stateSelector,
                defaultText: 'Select State',
                selectedId: selectedValues.stateId
            });

            if (selectedValues.stateId) {
                bindDropdown({
                    url: endpoints.city,
                    paramKey: 'stateId',
                    paramValue: selectedValues.stateId,
                    targetSelector: citySelector,
                    defaultText: 'Select City',
                    selectedId: selectedValues.cityId
                });

                if (selectedValues.cityId) {
                    bindDropdown({
                        url: endpoints.area,
                        paramKey: 'cityId',
                        paramValue: selectedValues.cityId,
                        targetSelector: areaSelector,
                        
                        selectedId: selectedValues.areaId
                    });
                }
            }
        }
    }

    return {
        resetDropdown,
        bindDropdown,
        bindCascadingDropdowns
    };
})();

function ValidateAddress() {
    $("#Address_CityId, #Address_StateId, #Address_CountryId").on("change", function () {
        $(this).valid();
    });

    $("#CityId, #StateId, #CountryId").on("change", function () {
        $(this).valid();
    });
}



let autocomplete;

function initAutocomplete() {
    const input = document.getElementById("googleAddress");

    if (!input || !(input instanceof HTMLInputElement)) {
        console.error("Element with ID 'googleAddress' is missing or not an <input>.");
        return;
    }

    autocomplete = new google.maps.places.Autocomplete(input, {
        types: ["geocode"],
        componentRestrictions: { country: ["om", "sy"] } 
    });

    autocomplete.addListener("place_changed", fillInAddress);
}

function fillInAddress() {
    if (!autocomplete) return;

    const place = autocomplete.getPlace();

    if (place.geometry && place.geometry.location) {
        $("#LatitudeId").val(place.geometry.location.lat());
        $("#LongitudeId").val(place.geometry.location.lng());
    }

    /*const address = place.formatted_address || '';*/
    const components = place.address_components || [];

    //$("#AddressLine1").val(address.substring(0, 100));
    //$("#AddressLine2").val(address.length > 100 ? address.substring(100, 200) : '');

    let postalCode = '', country = '', state = '', city = '', area = '';

    components.forEach(component => {
        const types = component.types || [];

        if (types.includes("postal_code")) postalCode = component.long_name;
        if (types.includes("country")) country = component.long_name;
        if (types.includes("administrative_area_level_1")) state = component.long_name;
        if (types.includes("locality")) city = component.long_name;
        if (types.includes("sublocality") || types.includes("neighborhood")) area = component.long_name;
    });

    $("#PostalCodeId").val(postalCode);

    const dropdowns = ['#CountryId', '#StateId', '#CityId', '#AreaId'];

    dropdowns.forEach(id => {
        $(id).val('').selectpicker('refresh');

    });


    waitForOptionAndSelect($('#CountryId'), country)
        .then(() => triggerChangeAndWait($('#CountryId'), $('#StateId'), state))
        .then(() => triggerChangeAndWait($('#StateId'), $('#CityId'), city))
        .then(() => triggerChangeAndWait($('#CityId'), $('#AreaId'), area))
        .then(() => {
            $('#location-dropdowns').fadeIn();
        })
        .catch(err => console.error("Dropdown binding error:", err));
}

function selectOptionByText($dropdown, text) {
    let found = false;
    const compareText = text.toLowerCase();

    $dropdown.find('option').each(function () {
        if ($(this).text().trim().toLowerCase() === compareText) {
            $(this).prop('selected', true);
            found = true;
            return false;
        }
    });

    $dropdown.selectpicker('refresh');
    return found;
}
function waitForOptionAndSelect($dropdown, text, timeout = 7000) {
    return new Promise((resolve, reject) => {
        const start = Date.now();
        const compareText = text.toLowerCase();

        (function checkOption() {
            const optionExists = $dropdown.find('option').filter(function () {
                return $(this).text().trim().toLowerCase() === compareText;
            }).length > 0;

            if (optionExists) {
                const selected = selectOptionByText($dropdown, text);
                selected ? resolve() : reject(`"${text}" not found in ${$dropdown.attr('id')}`);
            } else if (Date.now() - start > timeout) {
                reject(`Timeout waiting for "${text}" in #${$dropdown.attr('id')}`);
            } else {
                setTimeout(checkOption, 1000);
            }
        })();
    });
}



function triggerChangeAndWait($currentDropdown, $nextDropdown, nextText) {
    return new Promise((resolve, reject) => {
        $currentDropdown.trigger('change');

        setTimeout(() => {
            waitForOptionAndSelect($nextDropdown, nextText).then(resolve).catch(reject);
        }, 1000);
    });
}

$('.common-select2 select').select({
    width: '100%',
    language: {
        noResults: function () {
            return 'No record found';
        }
    },
    escapeMarkup: function (markup) {
        return markup;
    }
});
window.DropdownHelper = (function () {

    $('.custom-select').attr('data-live-search', 'true');


    //function resetDropdown(selector, defaultText = "Select") {
    //    $(selector).empty().append(`<option value="">${defaultText}</option>`);
    //    $(selector).selectpicker('refresh');
    //}

    function resetDropdown(selector) {
        // Bootstrap 5 does NOT need selectpicker
        $(selector).trigger('change');
    }


    function bindDropdown({ url, paramKey, paramValue, targetSelector, defaultText = "Select", selectedId = null }) {
        resetDropdown(targetSelector, defaultText);

        if (!paramValue) return;

        $.get(url, { [paramKey]: paramValue }, function (data) {
            if (data.success) {
                const $dropdown = $(targetSelector);
                $dropdown.empty();
                $dropdown.append(`<option value="">` + defaultText + `</option>`);

                $.each(data.data, function (i, item) {
                    $dropdown.append(`<option value="${item.id}" ${selectedId == item.id ? 'selected' : ''}>${item.name}</option>`);
                });

                $dropdown.selectpicker('refresh');
            }
        });
    }

    function bindCascadingDropdowns(options) {
        const {
            countrySelector = options.countrySelector,
            stateSelector = options.stateSelector,
            citySelector = options.citySelector,
            areaSelector = options.areaSelector,
            endpoints,
            selectedValues = {}
        } = options;

        $(document).on('change', countrySelector, function () {
            const countryId = $(this).val();
            resetDropdown(stateSelector, "Select State");
            resetDropdown(citySelector, "Select City");
            resetDropdown(areaSelector, "Select Area");

            bindDropdown({
                url: endpoints.state,
                paramKey: 'countryId',
                paramValue: countryId,
                targetSelector: stateSelector,
                defaultText: 'Select State'
            });
        });

        $(document).on('change', stateSelector, function () {
            const stateId = $(this).val();
            resetDropdown(citySelector, "Select City");
            resetDropdown(areaSelector, "Select Area");

            bindDropdown({
                url: endpoints.city,
                paramKey: 'stateId',
                paramValue: stateId,
                targetSelector: citySelector,
                defaultText: 'Select City'
            });
        });

        $(document).on('change', citySelector, function () {
            const cityId = $(this).val();
            resetDropdown(areaSelector, "Select Area");

            bindDropdown({
                url: endpoints.area,
                paramKey: 'cityId',
                paramValue: cityId,
                targetSelector: areaSelector,
                defaultText: 'Select Area'
            });
        });

        if (selectedValues.countryId) {
            bindDropdown({
                url: endpoints.state,
                paramKey: 'countryId',
                paramValue: selectedValues.countryId,
                targetSelector: stateSelector,
                defaultText: 'Select State',
                selectedId: selectedValues.stateId
            });

            if (selectedValues.stateId) {
                bindDropdown({
                    url: endpoints.city,
                    paramKey: 'stateId',
                    paramValue: selectedValues.stateId,
                    targetSelector: citySelector,
                    defaultText: 'Select City',
                    selectedId: selectedValues.cityId
                });

              
            }
        }
    }

    return {
        resetDropdown,
        bindDropdown,
        bindCascadingDropdowns
    };
})();

function ValidateAddress() {
    $("#Address_AreaCodeId, #Address_CityId, #Address_StateId, #Address_CountryId").on("change", function () {
        $(this).valid();
    });

    $("#AreaId, #CityId, #StateId, #CountryId").on("change", function () {
        $(this).valid();
    });
}



//let autocomplete;

//function initAutocomplete() {
//    const input = document.getElementById("googleAddress");

//    if (!input || !(input instanceof HTMLInputElement)) {
//        console.error("Element with ID 'googleAddress' is missing or not an <input>.");
//        return;
//    }

//    autocomplete = new google.maps.places.Autocomplete(input, {
//        types: ["geocode"],
//        componentRestrictions: { country: ["om", "sy"] } 
//    });

//    autocomplete.addListener("place_changed", fillInAddress);
//}

//function fillInAddress() {
//    if (!autocomplete) return;

//    const place = autocomplete.getPlace();

//    if (place.geometry && place.geometry.location) {
//        $("#LatitudeId").val(place.geometry.location.lat());
//        $("#LongitudeId").val(place.geometry.location.lng());
//    }

//    /*const address = place.formatted_address || '';*/
//    const components = place.address_components || [];

//    //$("#AddressLine1").val(address.substring(0, 100));
//    //$("#AddressLine2").val(address.length > 100 ? address.substring(100, 200) : '');

//    let postalCode = '', country = '', state = '', city = '', area = '';

//    components.forEach(component => {
//        const types = component.types || [];

//        if (types.includes("postal_code")) postalCode = component.long_name;
//        if (types.includes("country")) country = component.long_name;
//        if (types.includes("administrative_area_level_1")) state = component.long_name;
//        if (types.includes("locality")) city = component.long_name;
//        if (types.includes("sublocality") || types.includes("neighborhood")) area = component.long_name;
//    });

//    $("#PostalCodeId").val(postalCode);

//    const dropdowns = ['#CountryId', '#StateId', '#CityId', '#AreaId'];

//    dropdowns.forEach(id => {
//        $(id).val('').selectpicker('refresh');

//    });


//    waitForOptionAndSelect($('#CountryId'), country)
//        .then(() => triggerChangeAndWait($('#CountryId'), $('#StateId'), state))
//        .then(() => triggerChangeAndWait($('#StateId'), $('#CityId'), city))
//        .then(() => triggerChangeAndWait($('#CityId'), $('#AreaId'), area))
//        .then(() => {
//            $('#location-dropdowns').fadeIn();
//        })
//        .catch(err => console.error("Dropdown binding error:", err));
//}

//function selectOptionByText($dropdown, text) {
//    let found = false;
//    const compareText = text.toLowerCase();

//    $dropdown.find('option').each(function () {
//        if ($(this).text().trim().toLowerCase() === compareText) {
//            $(this).prop('selected', true);
//            found = true;
//            return false;
//        }
//    });

//    $dropdown.selectpicker('refresh');
//    return found;
//}
//function waitForOptionAndSelect($dropdown, text, timeout = 7000) {
//    return new Promise((resolve, reject) => {
//        const start = Date.now();
//        const compareText = text.toLowerCase();

//        (function checkOption() {
//            const optionExists = $dropdown.find('option').filter(function () {
//                return $(this).text().trim().toLowerCase() === compareText;
//            }).length > 0;

//            if (optionExists) {
//                const selected = selectOptionByText($dropdown, text);
//                selected ? resolve() : reject(`"${text}" not found in ${$dropdown.attr('id')}`);
//            } else if (Date.now() - start > timeout) {
//                reject(`Timeout waiting for "${text}" in #${$dropdown.attr('id')}`);
//            } else {
//                setTimeout(checkOption, 1000);
//            }
//        })();
//    });
//}



//function triggerChangeAndWait($currentDropdown, $nextDropdown, nextText) {
//    return new Promise((resolve, reject) => {
//        $currentDropdown.trigger('change');

//        setTimeout(() => {
//            waitForOptionAndSelect($nextDropdown, nextText).then(resolve).catch(reject);
//        }, 1000);
//    });
//}


