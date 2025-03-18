// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import './add_jquery'
import "@nathanvda/cocoon"
import "@hotwired/turbo-rails"
import "controllers"
import "custom/image_upload"
require("jquery")
require("@nathanvda/cocoon")
import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery

(function(){
  alert("jQuery 動いた！")
})