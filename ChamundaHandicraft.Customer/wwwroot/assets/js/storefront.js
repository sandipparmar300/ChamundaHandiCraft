/* ==========================================================================
   Chamunda Handicraft Storefront — shell behaviour
   No framework. Progressive enhancement only: every flow works without JS
   except the overlays, which have real page fallbacks.
   ========================================================================== */
(function () {
    'use strict';

    var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    /* ---------------------------------------------------------------------
       Theme — light / dark / system, persisted per device
       --------------------------------------------------------------------- */
    var Theme = {
        KEY: 'chamunda-theme',

        resolve: function (pref) {
            if (pref === 'system' || !pref) {
                return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
            }
            return pref;
        },

        apply: function (pref) {
            document.documentElement.setAttribute('data-theme', Theme.resolve(pref));
            document.documentElement.setAttribute('data-theme-pref', pref || 'system');
        },

        set: function (pref) {
            try { localStorage.setItem(Theme.KEY, pref); } catch (e) { }
            Theme.apply(pref);
        },

        get: function () {
            try { return localStorage.getItem(Theme.KEY) || 'system'; } catch (e) { return 'system'; }
        },

        toggle: function () {
            Theme.set(Theme.resolve(Theme.get()) === 'dark' ? 'light' : 'dark');
        }
    };

    Theme.apply(Theme.get());

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () {
        if (Theme.get() === 'system') Theme.apply('system');
    });

    /* ---------------------------------------------------------------------
       Toasts — CMP-FBK-Toast
       Success announced politely, errors assertively (A11Y-11).
       --------------------------------------------------------------------- */
    var ICONS = {
        success: 'circle-check',
        error: 'circle-alert',
        warning: 'triangle-alert',
        info: 'info'
    };

    function toastRegion() {
        var region = document.getElementById('toastRegion');
        if (!region) {
            region = document.createElement('div');
            region.id = 'toastRegion';
            region.className = 'toast-region';
            region.setAttribute('aria-live', 'polite');
            region.setAttribute('aria-atomic', 'false');
            document.body.appendChild(region);
        }
        return region;
    }

    function toast(message, opts) {
        opts = opts || {};
        var type = opts.type || 'success';
        var el = document.createElement('div');

        el.className = 'toast toast--' + type;
        el.setAttribute('role', type === 'error' ? 'alert' : 'status');

        el.innerHTML =
            '<span class="toast__icon"><svg class="ico" aria-hidden="true"><use href="#i-' + (ICONS[type] || 'info') + '"></use></svg></span>' +
            '<div class="toast__body">' +
                (opts.title ? '<div class="toast__title"></div>' : '') +
                '<div class="toast__msg"></div>' +
                (opts.actionLabel ? '<a class="toast__action" href="' + (opts.actionHref || '#') + '"></a>' : '') +
            '</div>' +
            '<button class="icon-btn icon-btn-sm" aria-label="Dismiss"><svg class="ico ico-sm" aria-hidden="true"><use href="#i-x"></use></svg></button>' +
            '<span class="toast__progress"></span>';

        if (opts.title) el.querySelector('.toast__title').textContent = opts.title;
        el.querySelector('.toast__msg').textContent = message;
        if (opts.actionLabel) el.querySelector('.toast__action').textContent = opts.actionLabel;

        function dismiss() {
            el.classList.add('is-leaving');
            setTimeout(function () { el.remove(); }, 250);
        }

        el.querySelector('button').addEventListener('click', dismiss);
        toastRegion().appendChild(el);
        setTimeout(dismiss, opts.duration || 4000);
        return el;
    }

    /* ---------------------------------------------------------------------
       Overlays — modal, drawer, sheet
       A11Y-10: focus trapped, labelled, focus restored on close.
       --------------------------------------------------------------------- */
    var openStack = [];

    function focusables(root) {
        return Array.prototype.filter.call(
            root.querySelectorAll('a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])'),
            function (el) { return el.offsetParent !== null || el === document.activeElement; }
        );
    }

    function lockScroll(on) {
        document.body.style.overflow = on ? 'hidden' : '';
    }

    function openOverlay(el) {
        if (!el || el.classList.contains('is-open')) return;

        var scrimId = el.getAttribute('data-scrim');
        var scrim = scrimId ? document.getElementById(scrimId) : el.previousElementSibling;

        if (scrim && scrim.classList.contains('scrim')) scrim.classList.add('is-open');

        el.classList.add('is-open');
        el.removeAttribute('aria-hidden');
        lockScroll(true);

        openStack.push({ el: el, scrim: scrim, returnTo: document.activeElement });

        var first = focusables(el)[0];
        if (first) setTimeout(function () { first.focus(); }, reduceMotion ? 0 : 120);
    }

    function closeOverlay(el) {
        var idx = -1;
        for (var i = openStack.length - 1; i >= 0; i--) {
            if (!el || openStack[i].el === el) { idx = i; break; }
        }
        if (idx === -1) return;

        var entry = openStack.splice(idx, 1)[0];
        entry.el.classList.remove('is-open');
        entry.el.setAttribute('aria-hidden', 'true');
        if (entry.scrim) entry.scrim.classList.remove('is-open');
        if (!openStack.length) lockScroll(false);
        if (entry.returnTo && entry.returnTo.focus) entry.returnTo.focus();
    }

    function closeTop() {
        if (openStack.length) closeOverlay(openStack[openStack.length - 1].el);
    }

    document.addEventListener('click', function (e) {
        var opener = e.target.closest('[data-open]');
        if (opener) {
            e.preventDefault();
            var targetId = opener.getAttribute('data-open');
            var overlay = document.getElementById(targetId);
            if (targetId === 'quickView' && overlay && opener.hasAttribute('data-qv-name')) {
                var title = overlay.querySelector('[data-qv-target="title"]');
                if (title) title.textContent = opener.getAttribute('data-qv-name') || '';
                var cat = overlay.querySelector('[data-qv-target="cat"]');
                if (cat) cat.textContent = opener.getAttribute('data-qv-cat') || '';
                var price = overlay.querySelector('[data-qv-target="price"]');
                if (price) price.textContent = opener.getAttribute('data-qv-price') || '';
                var img = overlay.querySelector('[data-qv-target="img"]');
                if (img && opener.getAttribute('data-qv-img')) img.src = opener.getAttribute('data-qv-img');
                var link = overlay.querySelector('[data-qv-target="link"]');
                if (link && opener.getAttribute('data-qv-url')) link.href = opener.getAttribute('data-qv-url');
            }
            openOverlay(overlay);
            return;
        }

        var closer = e.target.closest('[data-close]');
        if (closer) {
            e.preventDefault();
            var id = closer.getAttribute('data-close');
            closeOverlay(id ? document.getElementById(id) : closer.closest('.modal-scrim,.drawer,.sheet,.mobile-drawer,.ai-panel'));
            return;
        }

        if (e.target.classList.contains('scrim')) { closeTop(); return; }
        if (e.target.classList.contains('modal-scrim')) { closeOverlay(e.target); return; }
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && openStack.length) {
            e.preventDefault();
            closeTop();
            return;
        }

        if (e.key === 'Tab' && openStack.length) {
            var top = openStack[openStack.length - 1].el;
            var list = focusables(top);
            if (!list.length) return;

            var first = list[0];
            var last = list[list.length - 1];

            if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
            else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
    });

    /* ---------------------------------------------------------------------
       Header — compact on scroll, auto-hide on mobile scroll-down
       --------------------------------------------------------------------- */
    (function header() {
        var el = document.querySelector('.site-header');
        if (!el) return;

        var last = 0;
        var ticking = false;

        function update() {
            var y = window.scrollY;

            el.classList.toggle('is-compact', y > 120);

            if (window.innerWidth < 992) {
                el.classList.toggle('is-hidden', y > last && y > 200);
            } else {
                el.classList.remove('is-hidden');
            }

            last = y;
            ticking = false;
        }

        window.addEventListener('scroll', function () {
            if (!ticking) { window.requestAnimationFrame(update); ticking = true; }
        }, { passive: true });
    })();

    /* ---------------------------------------------------------------------
       Mega menu — hover on desktop, full keyboard traversal
       --------------------------------------------------------------------- */
    (function megamenu() {
        var triggers = document.querySelectorAll('[data-megamenu]');
        if (!triggers.length) return;

        var closeTimer;

        function panelFor(trigger) {
            return document.getElementById(trigger.getAttribute('data-megamenu'));
        }

        function closeAll() {
            document.querySelectorAll('.megamenu.is-open').forEach(function (p) {
                p.classList.remove('is-open');
            });
            triggers.forEach(function (t) { t.setAttribute('aria-expanded', 'false'); });
        }

        triggers.forEach(function (trigger) {
            var panel = panelFor(trigger);
            if (!panel) return;

            function open() {
                clearTimeout(closeTimer);
                closeAll();
                panel.classList.add('is-open');
                trigger.setAttribute('aria-expanded', 'true');
            }

            function scheduleClose() {
                closeTimer = setTimeout(closeAll, 180);
            }

            trigger.addEventListener('mouseenter', open);
            trigger.addEventListener('focus', open);
            trigger.addEventListener('mouseleave', scheduleClose);
            panel.addEventListener('mouseenter', function () { clearTimeout(closeTimer); });
            panel.addEventListener('mouseleave', scheduleClose);

            trigger.addEventListener('click', function (e) {
                e.preventDefault();
                if (panel.classList.contains('is-open')) closeAll(); else open();
            });

            trigger.addEventListener('keydown', function (e) {
                if (e.key === 'ArrowDown') {
                    e.preventDefault();
                    open();
                    var first = panel.querySelector('a');
                    if (first) first.focus();
                }
            });

            panel.addEventListener('keydown', function (e) {
                if (e.key === 'Escape') { closeAll(); trigger.focus(); }
            });
        });

        document.addEventListener('click', function (e) {
            if (!e.target.closest('.megamenu') && !e.target.closest('[data-megamenu]')) closeAll();
        });
    })();

    /* ---------------------------------------------------------------------
       Dropdowns
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var trigger = e.target.closest('[data-dropdown]');

        document.querySelectorAll('.dropdown.is-open').forEach(function (d) {
            if (!trigger || d !== trigger.closest('.dropdown')) {
                d.classList.remove('is-open');
                var btn = d.querySelector('[data-dropdown]');
                if (btn) btn.setAttribute('aria-expanded', 'false');
            }
        });

        if (trigger) {
            e.preventDefault();
            var dd = trigger.closest('.dropdown');
            var open = dd.classList.toggle('is-open');
            trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
        }
    });

    /* ---------------------------------------------------------------------
       Announcement bar — rotate max 3, dismissal persists 7 days
       --------------------------------------------------------------------- */
    (function announcement() {
        var bar = document.querySelector('.announcement-bar');
        if (!bar) return;

        try {
            var until = parseInt(localStorage.getItem('chamunda-announce-dismissed') || '0', 10);
            if (until > Date.now()) { bar.remove(); return; }
        } catch (e) { }

        var msgs = bar.querySelectorAll('.announcement-bar__msg');
        var i = 0;
        var timer;

        if (msgs.length > 1 && !reduceMotion) {
            timer = setInterval(function () {
                msgs[i].classList.remove('is-active');
                i = (i + 1) % msgs.length;
                msgs[i].classList.add('is-active');
            }, 5000);

            bar.addEventListener('mouseenter', function () { clearInterval(timer); });
        }

        var close = bar.querySelector('.announcement-bar__close');
        if (close) {
            close.addEventListener('click', function () {
                clearInterval(timer);
                bar.remove();
                try {
                    localStorage.setItem('chamunda-announce-dismissed', String(Date.now() + 7 * 864e5));
                } catch (e) { }
            });
        }
    })();

    /* ---------------------------------------------------------------------
       Accordions (also used for mobile footer columns and filter groups)
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var head = e.target.closest('.accordion__head');
        if (head) {
            var item = head.closest('.accordion__item');
            var accordion = item.closest('.accordion');
            var single = accordion && accordion.hasAttribute('data-single');

            if (single) {
                accordion.querySelectorAll('.accordion__item.is-open').forEach(function (other) {
                    if (other !== item) {
                        other.classList.remove('is-open');
                        var h = other.querySelector('.accordion__head');
                        if (h) h.setAttribute('aria-expanded', 'false');
                    }
                });
            }

            var open = item.classList.toggle('is-open');
            head.setAttribute('aria-expanded', open ? 'true' : 'false');
            return;
        }

        var footTitle = e.target.closest('.footer-col__title');
        if (footTitle) {
            var col = footTitle.closest('.footer-col');
            var isOpen = col.classList.toggle('is-open');
            footTitle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
            return;
        }

        var filterHead = e.target.closest('.filter-group__head');
        if (filterHead) {
            var group = filterHead.closest('.filter-group');
            var collapsed = group.classList.toggle('is-collapsed');
            filterHead.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
        }
    });

    /* ---------------------------------------------------------------------
       Tabs — deep-linkable via URL hash
       --------------------------------------------------------------------- */
    function activateTab(btn) {
        var group = btn.closest('.tabs');
        var target = btn.getAttribute('data-tab');

        group.querySelectorAll('.tabs__item').forEach(function (t) {
            var on = t === btn;
            t.classList.toggle('is-active', on);
            t.setAttribute('aria-selected', on ? 'true' : 'false');
            t.tabIndex = on ? 0 : -1;
        });

        var scope = group.closest('[data-tabs-scope]') || document;
        scope.querySelectorAll('.tab-panel').forEach(function (p) {
            p.classList.toggle('is-active', p.id === target);
        });
    }

    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.tabs__item[data-tab]');
        if (btn) { e.preventDefault(); activateTab(btn); }
    });

    document.addEventListener('keydown', function (e) {
        var btn = e.target.closest('.tabs__item[data-tab]');
        if (!btn || (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft')) return;

        var items = Array.prototype.slice.call(btn.closest('.tabs').querySelectorAll('.tabs__item'));
        var next = items[(items.indexOf(btn) + (e.key === 'ArrowRight' ? 1 : -1) + items.length) % items.length];
        next.focus();
        activateTab(next);
    });

    if (location.hash) {
        var hashTab = document.querySelector('.tabs__item[data-tab="' + location.hash.slice(1) + '"]');
        if (hashTab) activateTab(hashTab);
    }

    /* ---------------------------------------------------------------------
       Quantity stepper — debounced commit, keyboard support
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('.qty__btn');
        if (!btn) return;

        var wrap = btn.closest('.qty');
        var input = wrap.querySelector('.qty__input');
        var step = btn.getAttribute('data-step') === '-1' ? -1 : 1;
        var min = parseInt(input.min || '1', 10);
        var max = parseInt(input.max || '99', 10);
        var next = Math.min(max, Math.max(min, (parseInt(input.value, 10) || min) + step));

        if (next === parseInt(input.value, 10)) return;

        input.value = next;
        wrap.querySelector('[data-step="-1"]').disabled = next <= min;
        wrap.querySelector('[data-step="1"]').disabled = next >= max;
        input.dispatchEvent(new Event('change', { bubbles: true }));
    });

    /* ---------------------------------------------------------------------
       Wishlist toggle — works signed-out via a session wishlist
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('[data-wishlist]');
        if (!btn) return;

        e.preventDefault();
        e.stopPropagation();

        var on = btn.classList.toggle('is-on');
        btn.classList.add('just-toggled');
        setTimeout(function () { btn.classList.remove('just-toggled'); }, 400);

        var name = btn.getAttribute('data-product-name') || 'Item';
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
        btn.setAttribute('aria-label', (on ? 'Remove ' : 'Save ') + name + (on ? ' from' : ' to') + ' wishlist');

        bumpCounter('wishlistCount', on ? 1 : -1);

        toast(on ? 'Saved to your wishlist' : 'Removed from your wishlist', {
            actionLabel: on ? 'View' : null,
            actionHref: '/wishlist'
        });
    });

    function setCartCount(value) {
        var el = document.getElementById('cartCount');
        if (!el) return;
        value = Math.max(0, parseInt(value, 10) || 0);
        el.textContent = value;
        el.hidden = value === 0;
        el.classList.remove('just-changed');
        void el.offsetWidth;
        el.classList.add('just-changed');

        var live = document.getElementById('cartLive');
        if (live) live.textContent = 'Cart now has ' + value + ' item' + (value === 1 ? '' : 's');
    }

    function reloadMiniCart(openAfterReload, callback) {
        var mini = document.getElementById('miniCart');
        if (!mini) return;

        fetch('/cart/mini-partial')
            .then(function (r) { return r.text(); })
            .then(function (html) {
                var wasOpen = mini.classList.contains('is-open');
                var temp = document.createElement('div');
                temp.innerHTML = html.trim();
                var newMini = temp.firstElementChild;
                if (newMini && newMini.id === 'miniCart') {
                    mini.replaceWith(newMini);
                    if (wasOpen) {
                        for (var i = 0; i < openStack.length; i++) {
                            if (openStack[i].el === mini) {
                                openStack[i].el = newMini;
                            }
                        }
                        newMini.classList.add('is-open');
                        newMini.removeAttribute('aria-hidden');
                        var scrim = document.getElementById('globalScrim');
                        if (scrim) scrim.classList.add('is-open');
                        lockScroll(true);
                    } else if (openAfterReload) {
                        openOverlay(newMini);
                    }
                }
                if (callback) callback();
            })
            .catch(function (err) {
                console.error('Failed to reload minicart:', err);
                if (callback) callback();
            });
    }

    /* ---------------------------------------------------------------------
       Add to cart — Live Dynamic API integration
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('[data-add-to-cart]');
        if (!btn) return;

        e.preventDefault();
        e.stopPropagation();

        var card = btn.closest('.pcard, .pdp-info, .pcard-list, [data-cta-sentinel]');
        var container = card || btn.parentElement;

        var pid = parseInt(btn.getAttribute('data-product-id') || '0', 10);
        var slug = btn.getAttribute('data-slug') || '';
        var varId = btn.getAttribute('data-variant-id') ? parseInt(btn.getAttribute('data-variant-id'), 10) : null;

        var qtyInput = container ? container.querySelector('.qty__input') : null;
        var qty = qtyInput ? (parseInt(qtyInput.value, 10) || 1) : (parseInt(btn.getAttribute('data-qty') || '1', 10));

        btn.classList.add('is-loading');

        fetch('/cart/add', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({
                productId: pid,
                slug: slug,
                variantId: varId,
                quantity: qty
            })
        })
        .then(function (res) { return res.json(); })
        .then(function (res) {
            btn.classList.remove('is-loading');
            if (res.isSuccess) {
                var newCount = res.data && res.data.summary ? res.data.summary.itemCount : null;
                if (newCount !== null) {
                    setCartCount(newCount);
                } else {
                    bumpCounter('cartCount', qty);
                }

                var img = card && card.querySelector('img');
                if (img && !reduceMotion) flyToCart(img);

                var shouldOpen = btn.hasAttribute('data-open-minicart');
                reloadMiniCart(shouldOpen);

                toast(res.message || 'Added to cart', {
                    type: 'success',
                    actionLabel: 'View cart',
                    actionHref: '/cart'
                });
            } else {
                toast(res.message || 'Unable to add to cart', { type: 'error' });
            }
        })
        .catch(function (err) {
            btn.classList.remove('is-loading');
            toast('Network error while adding to cart. Please try again.', { type: 'error' });
        });
    });

    /* ---------------------------------------------------------------------
       Mini-Cart Quantity & Remove controls
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var stepBtn = e.target.closest('[data-mini-step]');
        if (stepBtn) {
            e.preventDefault();
            e.stopPropagation();

            var cartItemId = parseInt(stepBtn.getAttribute('data-cart-item-id') || '0', 10);
            var delta = parseInt(stepBtn.getAttribute('data-mini-step') || '0', 10);
            var parentQty = stepBtn.closest('.qty');
            var input = parentQty ? parentQty.querySelector('.qty__input') : null;
            var currentQty = input ? (parseInt(input.value, 10) || 1) : 1;
            var newQty = currentQty + delta;

            if (newQty <= 0) {
                fetch('/cart/remove', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                    body: JSON.stringify({ cartItemId: cartItemId })
                })
                .then(function (r) { return r.json(); })
                .then(function (res) {
                    if (res.isSuccess) {
                        if (res.data && res.data.summary) setCartCount(res.data.summary.itemCount);
                        reloadMiniCart(true);
                        if (window.location.pathname.toLowerCase().startsWith('/cart')) window.location.reload();
                    } else {
                        toast(res.message || 'Failed to remove item', { type: 'error' });
                    }
                });
            } else {
                fetch('/cart/update-qty', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                    body: JSON.stringify({ cartItemId: cartItemId, quantity: newQty })
                })
                .then(function (r) { return r.json(); })
                .then(function (res) {
                    if (res.isSuccess) {
                        if (res.data && res.data.summary) setCartCount(res.data.summary.itemCount);
                        reloadMiniCart(true);
                        if (window.location.pathname.toLowerCase().startsWith('/cart')) window.location.reload();
                    } else {
                        toast(res.message || 'Failed to update quantity', { type: 'error' });
                    }
                });
            }
            return;
        }

        var removeBtn = e.target.closest('[data-mini-remove]');
        if (removeBtn) {
            e.preventDefault();
            e.stopPropagation();

            var id = parseInt(removeBtn.getAttribute('data-mini-remove') || '0', 10);
            fetch('/cart/remove', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                body: JSON.stringify({ cartItemId: id })
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                if (res.isSuccess) {
                    if (res.data && res.data.summary) setCartCount(res.data.summary.itemCount);
                    reloadMiniCart(true);
                    if (window.location.pathname.toLowerCase().startsWith('/cart')) window.location.reload();
                } else {
                    toast(res.message || 'Failed to remove item', { type: 'error' });
                }
            });
            return;
        }
    });

    /* ---------------------------------------------------------------------
       Full Cart Page Quantity, Remove & Coupons
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var cartStepBtn = e.target.closest('[data-cart-step]');
        if (cartStepBtn) {
            e.preventDefault();
            var id = parseInt(cartStepBtn.getAttribute('data-cart-item-id') || '0', 10);
            var step = parseInt(cartStepBtn.getAttribute('data-cart-step') || '0', 10);
            var wrap = cartStepBtn.closest('.qty');
            var input = wrap ? wrap.querySelector('.qty__input') : null;
            var current = input ? (parseInt(input.value, 10) || 1) : 1;
            var next = current + step;

            if (next <= 0) {
                cartStepBtn.disabled = true;
                fetch('/cart/remove', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                    body: JSON.stringify({ cartItemId: id })
                })
                .then(function (r) { return r.json(); })
                .then(function (res) {
                    if (res.isSuccess) {
                        window.location.reload();
                    } else {
                        cartStepBtn.disabled = false;
                        toast(res.message || 'Unable to remove item', { type: 'error' });
                    }
                })
                .catch(function () {
                    cartStepBtn.disabled = false;
                    toast('Network error. Please try again.', { type: 'error' });
                });
            } else {
                cartStepBtn.disabled = true;
                fetch('/cart/update-qty', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                    body: JSON.stringify({ cartItemId: id, quantity: next })
                })
                .then(function (r) { return r.json(); })
                .then(function (res) {
                    if (res.isSuccess) {
                        window.location.reload();
                    } else {
                        cartStepBtn.disabled = false;
                        toast(res.message || 'Unable to update quantity', { type: 'error' });
                    }
                })
                .catch(function () {
                    cartStepBtn.disabled = false;
                    toast('Network error. Please try again.', { type: 'error' });
                });
            }
            return;
        }

        var cartRemoveBtn = e.target.closest('[data-cart-remove]');
        if (cartRemoveBtn) {
            e.preventDefault();
            var id = parseInt(cartRemoveBtn.getAttribute('data-cart-remove') || '0', 10);
            cartRemoveBtn.disabled = true;
            fetch('/cart/remove', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                body: JSON.stringify({ cartItemId: id })
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                if (res.isSuccess) {
                    window.location.reload();
                } else {
                    cartRemoveBtn.disabled = false;
                    toast(res.message || 'Unable to remove item', { type: 'error' });
                }
            })
            .catch(function () {
                cartRemoveBtn.disabled = false;
                toast('Network error. Please try again.', { type: 'error' });
            });
            return;
        }

        var applyBtn = e.target.closest('#btnApplyCoupon');
        if (applyBtn) {
            e.preventDefault();
            var codeInput = document.getElementById('couponCode');
            var code = codeInput ? codeInput.value.trim() : '';
            if (!code) {
                toast('Please enter a coupon code', { type: 'warning' });
                return;
            }
            applyBtn.disabled = true;
            fetch('/cart/apply-coupon', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                body: JSON.stringify({ couponCode: code })
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                applyBtn.disabled = false;
                if (res.isSuccess) {
                    toast(res.message || 'Coupon applied successfully!', { type: 'success' });
                    setTimeout(function () { window.location.reload(); }, 600);
                } else {
                    toast(res.message || 'Invalid coupon code', { type: 'error' });
                }
            })
            .catch(function () {
                applyBtn.disabled = false;
                toast('Network error. Please try again.', { type: 'error' });
            });
            return;
        }

        var applyPresetBtn = e.target.closest('[data-apply-coupon-code]');
        if (applyPresetBtn) {
            e.preventDefault();
            var code = applyPresetBtn.getAttribute('data-apply-coupon-code');
            applyPresetBtn.disabled = true;
            fetch('/cart/apply-coupon', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                body: JSON.stringify({ couponCode: code })
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                applyPresetBtn.disabled = false;
                if (res.isSuccess) {
                    toast(res.message || 'Coupon applied successfully!', { type: 'success' });
                    setTimeout(function () { window.location.reload(); }, 600);
                } else {
                    toast(res.message || 'Invalid coupon code', { type: 'error' });
                }
            })
            .catch(function () {
                applyPresetBtn.disabled = false;
                toast('Network error. Please try again.', { type: 'error' });
            });
            return;
        }

        var removeCouponBtn = e.target.closest('[data-cart-remove-coupon]');
        if (removeCouponBtn) {
            e.preventDefault();
            fetch('/cart/remove-coupon', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
            })
            .then(function (r) { return r.json(); })
            .then(function (res) {
                toast('Coupon removed', { type: 'success' });
                setTimeout(function () { window.location.reload(); }, 600);
            });
            return;
        }
    });

    function flyToCart(img) {
        var target = document.querySelector('[data-cart-icon]');
        if (!target) return;

        var from = img.getBoundingClientRect();
        var to = target.getBoundingClientRect();
        var ghost = img.cloneNode();

        ghost.style.cssText =
            'position:fixed;z-index:1400;pointer-events:none;border-radius:8px;object-fit:cover;' +
            'left:' + from.left + 'px;top:' + from.top + 'px;width:' + from.width + 'px;height:' + from.height + 'px;' +
            'transition:all 450ms cubic-bezier(0.3,0,1,1);opacity:0.9';

        document.body.appendChild(ghost);

        requestAnimationFrame(function () {
            ghost.style.left = (to.left + to.width / 2 - 12) + 'px';
            ghost.style.top = (to.top + to.height / 2 - 12) + 'px';
            ghost.style.width = '24px';
            ghost.style.height = '24px';
            ghost.style.opacity = '0.2';
        });

        setTimeout(function () { ghost.remove(); }, 480);
    }

    function bumpCounter(id, delta) {
        var el = document.getElementById(id);
        if (!el) return;

        var value = Math.max(0, (parseInt(el.textContent, 10) || 0) + delta);
        el.textContent = value;
        el.hidden = value === 0;
        el.classList.remove('just-changed');
        void el.offsetWidth;
        el.classList.add('just-changed');

        // A11Y-18: cart and wishlist counts announced on change
        var live = document.getElementById('cartLive');
        if (live) live.textContent = (id === 'cartCount' ? 'Cart' : 'Wishlist') + ' now has ' + value + ' item' + (value === 1 ? '' : 's');
    }

    /* ---------------------------------------------------------------------
       Search — suggestions panel, debounce 200ms, keyboard traversal
       --------------------------------------------------------------------- */
    document.querySelectorAll('.search-bar').forEach(function (bar) {
        var input = bar.querySelector('.search-bar__input');
        var panel = bar.querySelector('.search-suggest');
        var clear = bar.querySelector('.search-bar__clear');
        if (!input) return;

        function sync() { bar.classList.toggle('has-value', input.value.length > 0); }

        var debounceTimer = null;
        input.addEventListener('input', function () {
            sync();
            if (!panel) return;
            var q = input.value.trim();
            clearTimeout(debounceTimer);
            if (q.length < 2) return;
            debounceTimer = setTimeout(function () {
                fetch('/search/suggest?q=' + encodeURIComponent(q))
                    .then(function (r) { return r.json(); })
                    .then(function (res) {
                        if (!res || !res.isSuccess || !res.data) return;
                        var pBox = panel.querySelector('[data-suggest-products]');
                        var cBox = panel.querySelector('[data-suggest-categories]');
                        var foot = panel.querySelector('[data-suggest-footer]');
                        if (res.data.products && res.data.products.length > 0 && pBox) {
                            pBox.innerHTML = res.data.products.slice(0, 4).map(function (p) {
                                return '<a class="search-suggest__row search-suggest__product" href="/p/' + encodeURIComponent(p.slug) + '" role="option">' +
                                    '<img src="' + (p.imageUrl || '/assets/images/placeholders/brass.svg') + '" alt="" loading="lazy" width="48" height="48" />' +
                                    '<span class="grow"><span style="display:block">' + escapeHtml(p.name) + '</span><span class="t-body-xs text-tertiary-c">' + escapeHtml(p.categoryName || '') + '</span></span>' +
                                    '<span class="t-body-sm tabular" style="font-weight:600">₹' + (p.price || 0).toLocaleString('en-IN') + '</span></a>';
                            }).join('');
                        }
                        if (res.data.categories && res.data.categories.length > 0 && cBox) {
                            cBox.innerHTML = res.data.categories.slice(0, 4).map(function (c) {
                                return '<a class="search-suggest__row" href="/c/' + encodeURIComponent(c.slug) + '" role="option">' + escapeHtml(c.name) + ' <span class="text-tertiary-c">(' + (c.productCount || 0) + ')</span></a>';
                            }).join('');
                        }
                        if (foot) {
                            foot.href = '/search?q=' + encodeURIComponent(q);
                            var span = foot.querySelector('span');
                            if (span) span.textContent = 'See all results for “' + q + '”';
                        }
                    })
                    .catch(function () { /* silent fallback */ });
            }, 250);
        });
        sync();

        function escapeHtml(str) {
            if (!str) return '';
            return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        }

        if (clear) {
            clear.addEventListener('click', function () {
                input.value = '';
                sync();
                input.focus();
            });
        }

        if (!panel) return;

        input.addEventListener('focus', function () { panel.classList.add('is-open'); });

        document.addEventListener('click', function (e) {
            if (!bar.contains(e.target)) panel.classList.remove('is-open');
        });

        input.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') { panel.classList.remove('is-open'); return; }
            if (e.key !== 'ArrowDown' && e.key !== 'ArrowUp') return;

            e.preventDefault();

            var rows = Array.prototype.slice.call(panel.querySelectorAll('.search-suggest__row'));
            if (!rows.length) return;

            var current = panel.querySelector('.search-suggest__row.is-highlighted');
            var idx = rows.indexOf(current);
            idx = e.key === 'ArrowDown' ? (idx + 1) % rows.length : (idx - 1 + rows.length) % rows.length;

            rows.forEach(function (r) { r.classList.remove('is-highlighted'); });
            rows[idx].classList.add('is-highlighted');
            rows[idx].focus();
        });
    });

    /* ---------------------------------------------------------------------
       Product rails — arrow paging, disable at the ends
       --------------------------------------------------------------------- */
    document.querySelectorAll('.rail-wrap').forEach(function (wrap) {
        var rail = wrap.querySelector('.rail');
        var prev = wrap.querySelector('.rail__arrow--prev');
        var next = wrap.querySelector('.rail__arrow--next');
        if (!rail) return;

        function sync() {
            if (prev) prev.disabled = rail.scrollLeft <= 4;
            if (next) next.disabled = rail.scrollLeft + rail.clientWidth >= rail.scrollWidth - 4;
        }

        function page(dir) {
            rail.scrollBy({ left: dir * rail.clientWidth * 0.8, behavior: reduceMotion ? 'auto' : 'smooth' });
        }

        if (prev) prev.addEventListener('click', function () { page(-1); });
        if (next) next.addEventListener('click', function () { page(1); });

        rail.addEventListener('scroll', sync, { passive: true });
        window.addEventListener('resize', sync);
        sync();
    });

    /* ---------------------------------------------------------------------
       Product gallery — thumbnail switching + keyboard
       --------------------------------------------------------------------- */
    document.querySelectorAll('[data-gallery]').forEach(function (gallery) {
        var main = gallery.querySelector('[data-gallery-main]');
        var counter = gallery.querySelector('[data-gallery-counter]');
        var thumbs = Array.prototype.slice.call(gallery.querySelectorAll('.gallery__thumb'));
        if (!main || !thumbs.length) return;

        function show(i) {
            var thumb = thumbs[i];
            if (!thumb) return;

            var src = thumb.getAttribute('data-full') || thumb.querySelector('img').src;

            main.style.opacity = '0';
            setTimeout(function () {
                main.src = src;
                main.alt = thumb.querySelector('img').alt;
                main.style.opacity = '1';
            }, reduceMotion ? 0 : 120);

            thumbs.forEach(function (t, j) {
                t.classList.toggle('is-active', j === i);
                t.setAttribute('aria-selected', j === i ? 'true' : 'false');
            });

            if (counter) counter.textContent = (i + 1) + ' / ' + thumbs.length;
            gallery.setAttribute('data-index', i);
        }

        thumbs.forEach(function (t, i) {
            t.addEventListener('click', function () { show(i); });
        });

        gallery.addEventListener('keydown', function (e) {
            if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
            var i = parseInt(gallery.getAttribute('data-index') || '0', 10);
            show((i + (e.key === 'ArrowRight' ? 1 : -1) + thumbs.length) % thumbs.length);
        });

        main.style.transition = 'opacity 150ms ease';
    });

    /* ---------------------------------------------------------------------
       Option selectors — required options block Add to Cart with a reason
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var pill = e.target.closest('.option-pill:not(.is-oos)');
        if (!pill) return;

        var group = pill.closest('.option-group');
        group.querySelectorAll('.option-pill').forEach(function (p) {
            p.classList.remove('is-selected');
            p.setAttribute('aria-checked', 'false');
        });

        pill.classList.add('is-selected');
        pill.setAttribute('aria-checked', 'true');
        group.classList.remove('has-error');

        var label = group.querySelector('.option-group__value');
        if (label) label.textContent = pill.getAttribute('data-label') || pill.textContent.trim();

        var input = group.querySelector('input[type="hidden"]');
        if (input) input.value = pill.getAttribute('data-value') || '';

        var varId = pill.getAttribute('data-variant-id');
        if (varId) {
            document.querySelectorAll('[data-add-to-cart]').forEach(function (btn) {
                btn.setAttribute('data-variant-id', varId);
            });
            var price = pill.getAttribute('data-variant-price');
            if (price) {
                var priceEl = document.querySelector('.pdp-info .price__now');
                if (priceEl) priceEl.textContent = '₹' + parseFloat(price).toLocaleString('en-IN');
            }
        }
    });

    document.querySelectorAll('.select-card').forEach(function (card) {
        card.addEventListener('click', function () {
            var name = card.getAttribute('data-group');
            if (!name) return;

            document.querySelectorAll('.select-card[data-group="' + name + '"]').forEach(function (c) {
                c.classList.remove('is-selected');
            });

            card.classList.add('is-selected');
            var radio = card.querySelector('input[type="radio"]');
            if (radio) radio.checked = true;
        });
    });

    /* ---------------------------------------------------------------------
       Sticky PDP CTA — appears when the inline CTA scrolls out of view
       --------------------------------------------------------------------- */
    (function stickyCta() {
        var sentinel = document.querySelector('[data-cta-sentinel]');
        var bar = document.querySelector('.pdp-sticky');
        if (!sentinel || !bar || !('IntersectionObserver' in window)) return;

        new IntersectionObserver(function (entries) {
            bar.classList.toggle('is-visible', !entries[0].isIntersecting);
        }, { rootMargin: '-80px 0px 0px 0px' }).observe(sentinel);
    })();

    /* ---------------------------------------------------------------------
       Back-to-top FAB — appears after two viewports
       --------------------------------------------------------------------- */
    (function backToTop() {
        var fab = document.querySelector('[data-back-to-top]');
        if (!fab) return;

        window.addEventListener('scroll', function () {
            fab.classList.toggle('is-visible', window.scrollY > window.innerHeight * 2);
        }, { passive: true });

        fab.addEventListener('click', function () {
            window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
        });
    })();

    /* ---------------------------------------------------------------------
       Scroll reveal — once only, staggered, disabled under reduced motion
       --------------------------------------------------------------------- */
    (function reveal() {
        var items = document.querySelectorAll('.reveal');
        if (!items.length) return;

        if (reduceMotion || !('IntersectionObserver' in window)) {
            items.forEach(function (el) { el.classList.add('is-visible'); });
            return;
        }

        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry, i) {
                if (!entry.isIntersecting) return;
                var delay = Math.min(i, 5) * 60;
                setTimeout(function () { entry.target.classList.add('is-visible'); }, delay);
                io.unobserve(entry.target);
            });
        }, { threshold: 0.15 });

        items.forEach(function (el) { io.observe(el); });
    })();

    /* ---------------------------------------------------------------------
       Password visibility + strength
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var toggle = e.target.closest('.pw-toggle');
        if (!toggle) return;

        var input = toggle.closest('.input-group').querySelector('input');
        var showing = input.type === 'text';

        input.type = showing ? 'password' : 'text';
        toggle.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
        toggle.querySelector('use').setAttribute('href', showing ? '#i-eye' : '#i-eye-off');
    });

    document.querySelectorAll('[data-pw-strength]').forEach(function (input) {
        var meter = document.getElementById(input.getAttribute('data-pw-strength'));
        if (!meter) return;

        input.addEventListener('input', function () {
            var v = input.value;
            var score = 0;
            if (v.length >= 8) score++;
            if (/[A-Z]/.test(v) && /[a-z]/.test(v)) score++;
            if (/\d/.test(v)) score++;
            if (/[^A-Za-z0-9]/.test(v)) score++;
            meter.setAttribute('data-score', v ? score : 0);
        });
    });

    /* ---------------------------------------------------------------------
       OTP input — auto-advance and paste support
       --------------------------------------------------------------------- */
    document.querySelectorAll('.otp').forEach(function (otp) {
        var inputs = Array.prototype.slice.call(otp.querySelectorAll('input'));

        inputs.forEach(function (input, i) {
            input.addEventListener('input', function () {
                input.value = input.value.replace(/\D/g, '').slice(-1);
                if (input.value && inputs[i + 1]) inputs[i + 1].focus();
            });

            input.addEventListener('keydown', function (e) {
                if (e.key === 'Backspace' && !input.value && inputs[i - 1]) inputs[i - 1].focus();
            });

            input.addEventListener('paste', function (e) {
                e.preventDefault();
                var digits = (e.clipboardData.getData('text') || '').replace(/\D/g, '').split('');
                inputs.forEach(function (box, j) { box.value = digits[j] || ''; });
                (inputs[digits.length] || inputs[inputs.length - 1]).focus();
            });
        });
    });

    /* ---------------------------------------------------------------------
       Cookie consent — no pre-ticked consent, one-click reject
       --------------------------------------------------------------------- */
    (function cookies() {
        var bar = document.getElementById('cookieConsent');
        if (!bar) return;

        try {
            if (localStorage.getItem('chamunda-cookie-choice')) return;
        } catch (e) { }

        setTimeout(function () { bar.classList.add('is-open'); }, 1200);

        bar.querySelectorAll('[data-cookie-choice]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                try {
                    localStorage.setItem('chamunda-cookie-choice', btn.getAttribute('data-cookie-choice'));
                } catch (e) { }
                bar.classList.remove('is-open');
            });
        });
    })();

    /* ---------------------------------------------------------------------
       Copy-to-clipboard (order numbers, coupon codes)
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        var btn = e.target.closest('[data-copy]');
        if (!btn) return;

        var text = btn.getAttribute('data-copy');
        navigator.clipboard.writeText(text).then(function () {
            toast('Copied ' + text);
        }, function () {
            toast('Couldn’t copy. Select the text and copy manually.', { type: 'error' });
        });
    });

    /* ---------------------------------------------------------------------
       Theme toggle buttons
       --------------------------------------------------------------------- */
    document.addEventListener('click', function (e) {
        if (e.target.closest('[data-theme-toggle]')) Theme.toggle();
    });

    /* ---------------------------------------------------------------------
       Client-side form validation — "explain, don't block" (CX principle 12)
       --------------------------------------------------------------------- */
    document.querySelectorAll('form[data-validate]').forEach(function (form) {
        form.setAttribute('novalidate', 'novalidate');

        form.addEventListener('submit', function (e) {
            var firstBad = null;

            form.querySelectorAll('.field').forEach(function (field) {
                var input = field.querySelector('input, select, textarea');
                if (!input) return;

                var ok = input.checkValidity();
                field.classList.toggle('has-error', !ok);
                input.setAttribute('aria-invalid', ok ? 'false' : 'true');

                if (!ok) {
                    var msg = field.querySelector('.field__error');
                    if (msg && !msg.getAttribute('data-static')) {
                        var label = (field.querySelector('.field__label') || {}).textContent || 'This field';
                        msg.querySelector('span').textContent = input.value
                            ? 'Enter a valid ' + label.replace('*', '').trim().toLowerCase()
                            : label.replace('*', '').trim() + ' is required';
                    }
                    if (!firstBad) firstBad = input;
                }
            });

            if (firstBad) {
                e.preventDefault();
                firstBad.focus();
                firstBad.scrollIntoView({ block: 'center', behavior: reduceMotion ? 'auto' : 'smooth' });
            }
        });
    });

    /* ---------------------------------------------------------------------
       Public surface
       --------------------------------------------------------------------- */
    window.Chamunda = {
        toast: toast,
        theme: Theme,
        openOverlay: openOverlay,
        closeOverlay: closeOverlay,
        bumpCounter: bumpCounter
    };
})();
