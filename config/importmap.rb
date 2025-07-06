# Pin npm packages by running ./bin/importmap
# Asset Pipeline Configuration

pin "application", preload: true
pin "stimulus", to: "stimulus.min.js", preload: true
pin "stimulus-loading", to: "stimulus-loading.js", preload: true
pin "turbo", to: "turbo.min.js", preload: true
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/titans", under: "titans"
