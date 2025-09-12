# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "generate_description", to: "generate_description.js"
pin "generate_ai_image", to: "generate_ai_image.js"
pin_all_from "app/javascript/controllers", under: "controllers"
