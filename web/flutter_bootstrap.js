{{flutter_js}}
{{flutter_build_config}}

// No offline caching: always load the latest published version.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((regs) => {
    regs.forEach((r) => r.unregister());
  });
}

// Version the app file so browsers never reuse a stale main.dart.js.
// Replaced with the commit id by the deploy workflow.
const appVersion = '__APP_VERSION__';
for (const build of _flutter.buildConfig.builds) {
  if (build.compileTarget === 'dart2js') {
    build.mainJsPath = `main.dart.js?v=${appVersion}`;
  }
}

_flutter.loader.load();
