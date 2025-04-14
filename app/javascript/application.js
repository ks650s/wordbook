// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import { Application } from "@hotwired/stimulus" // Should exist already
// import RailsNestedForm from '@stimulus-components/rails-nested-form'

// const application = Application.start() // Should exist already
// application.register('nested-form', RailsNestedForm)
// import './add_jquery'

//import "@hotwired/turbo-rails"
// import "controllers"
// import "../custom/image_upload"

// require("@nathanvda/cocoon")
import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

import "bootsrap"
(function(){
  alert("jQuery 動いた！")
})

document.addEventListener("DOMContentLoaded", function () {
  console.log("add_fields の数: ", document.querySelectorAll('.add_fields').length);
});

import "@nathanvda/cocoon"