{ pkgs, lib, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  settings = {
    # Homepage and new windows → Blank Page.
    "browser.startup.homepage" = "https://browserleaks.com/ip";
    # Restore previous session
    "browser.startup.page" = 3;
    # New tabs → Blank Page.
    "browser.newtabpage.enabled" = false;

    # Density → Compact.
    "browser.uidensity" = 1;

    # Search Suggestions → Provide search suggestions.
    "browser.search.suggest.enabled" = false;
    # Show search suggestions in address bar results.
    "browser.urlbar.suggest.engines" = false;

    # Logins and Passwords → Ask to save logins and passwords for websites.
    "signon.autofillForms" = false;
    # Logins and Passwords → Suggest and generate strong passwords.
    "signon.generation.enabled" = false;
    # Logins and Passwords → Show alerts about passwords for breached websites.
    "signon.management.page.breach-alerts.enabled" = false;

    # Enhanced Tracking Protection → Custom → Cookies → All third-party cookies.
    "network.cookie.cookieBehavior" = 1;
    # Enhanced Tracking Protection → Custom → Tracking content → In all windows.
    "privacy.trackingprotection.enabled" = true;
    # Enhanced Tracking Protection → Custom → Cryptominers.
    "privacy.trackingprotection.cryptomining.enabled" = true;
    # Enhanced Tracking Protection → Custom → Fingerprinters.
    "privacy.trackingprotection.fingerprinting.enabled" = true;

    # Forms and Autofill.
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "extensions.formautofill.heuristics.enabled" = false;
    "extensions.formautofill.reauth.enabled" = false;
    "extensions.formautofill.section.enabled" = false;

    # Address Bar – Firefox Suggest → Suggestions from the web.
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    # Address Bar – Firefox Suggest → Suggestions from sponsors.
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;

    # Permissions → Autoplay → Default for all websites: → Block Audio and Video.
    "media.autoplay.default" = 5;

    # Firefox Data Collection and Use → Allow Firefox to send technical and interaction data to Mozilla.
    "datareporting.healthreport.uploadEnabled" = false;
    # Firefox Data Collection and Use → Allow Firefox to install and run studies.
    # https://mozilla.github.io/normandy/user/end_user_interaction.html
    "app.shield.optoutstudies.enabled" = false;
    # Firefox Data Collection and Use → Allow Firefox to send backlogged crash reports on your behalf.
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

    # Security → Block dangerous and deceptive content (disables
    # Google's ability to monitor your web traffic for malware, storing
    # the sites you visit).
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;

    # HTTPS-Only Mode → Enable HTTPS-Only Mode in all windows.
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;

    # Settings beyond this point aren't configurable via Firefox's
    # settings UI. Attempt to disable every boolean preference
    # containing the word "telemetry."
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
    "browser.newtabpage.activity-stream.telemetry.ut.events" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;
    "dom.security.unexpected_system_load_telemetry_enabled" = false;
    "network.trr.confirmation_telemetry_enabled" = false;
    "privacy.trackingprotection.origin_telemetry.enabled" = false;
    "security.app_menu.recordEventTelemetry" = false;
    "security.certerrors.recordEventTelemetry" = false;
    "security.identitypopup.recordEventTelemetry" = false;
    "security.protectionspopup.recordEventTelemetry" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.debugSlowSql" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.geckoview.streaming" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.pioneer-new-studies-available" = false;
    "toolkit.telemetry.reportingpolicy.firstRun" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.testing.overrideProductsCheck" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.updatePing.enabled" = false;

    # Attempt to disable every boolean preference containing the word
    # "recommend."
    "browser.newtabpage.activity-stream.feeds.recommendationprovider" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    "remote.prefs.recommended" = false;

    # Disable the proprietary Pocket service.
    # https://support.mozilla.org/en-US/kb/disable-or-re-enable-pocket-for-firefox
    "browser.newtabpage.activity-stream.discoverystream.saveToPocketCard.enabled" = false;
    "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
    "extensions.pocket.api" = "";
    "extensions.pocket.enabled" = false;
    "extensions.pocket.onSaveRecs" = false;
    "extensions.pocket.showHome" = false;
    "extensions.pocket.site" = false;
    "services.sync.prefs.sync.browser.newtabpage.activity-stream.section.highlights.includePocket" = false;

    # According to Bugzilla, this is only used for feature detection in
    # JS-land of whether or not Form Autofill is available:
    # https://bugzilla.mozilla.org/show_bug.cgi?id=1386120.
    "dom.forms.autocomplete.formautofill" = false;

    # Disable the Battery Status API to resist fingerprinting.
    "dom.battery.enabled" = false;

    # Disable the Notifications API to resist fingerprinting.
    "dom.webnotifications.enabled" = false;

    # Disable WebRTC to resist fingerprinting.
    # https://browserleaks.com/webrtc
    "media.peerconnection.enabled" = false;
    "media.peerconnection.turn.disable" = true;
    "media.peerconnection.use_document_iceservers" = false;
    "media.peerconnection.video.enabled" = false;
    "media.navigator.enabled" = false;

    # Disable the Geolocation API to resist fingerprinting.
    # https://browserleaks.com/geo
    "geo.enabled" = false;

    # Disable mozilla's screenshot service
    "extensions.screenshots.disabled" = true;

    # Disable mozilla's account service
    "identity.fxaccounts.enabled" = false;

    # Temporary workaround for nixpkgs issue #167785
    "security.sandbox.content.level" = 3;

    # These options break or reduce performance on many websites.
    "privacy.resistFingerprinting" = false;
    "webgl.disabled" = false;
    "privacy.donottrackheader.enabled" = false;

    # Disable periodic requests to tracking services to detect captive portal logins
    "network.captive-portal-service.enabled" = false;

    # Enable codegen for AVX/AVX2 supporting CPUs in webassembly jit
    "javascript.options.wasm_simd_avx" = true;

    # Prevent punycode phishing attacks
    "network.IDN_show_punycode" = true;

    # Slow down session saves from the default 15s to 120s.
    "browser.sessionstore.interval" = 120000;

    # Darken page and highlight found text when searching pages.
    "findbar.modalHighlight" = true;
    # Enable "Highlight All" in find UI by default
    "findbar.highlightAll" = true;
  };
in
{
  programs.firefox = {
    enable = true;

    profiles.default = {
      inherit settings;
      id = 0;
    };

    # Dummy package so that we can install Firefox with Homebrew.
    package = if isDarwin then (pkgs.runCommandLocal "" { } "mkdir $out") else pkgs.firefox-bin;
  };
}
