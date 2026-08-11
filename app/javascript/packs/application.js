// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

//*= require_self
//*= require jquery3
//*= required jquery_usj
//*= require popper
//*= require tether
//*= require bootstrap
//*= require toolgun
//*= require tree

import Rails from "@rails/ujs"
//import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import "bootstrap"
import "@hotwired/turbo-rails"

import "chartkick/chart.js"


Rails.start()
//Turbolinks.start()
ActiveStorage.start()
