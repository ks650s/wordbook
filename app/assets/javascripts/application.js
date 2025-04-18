//= require jquery
//= require jquery_ujs
//= require cocoon



console.log("JavaScript 読み込み済み");

document.addEventListener("DOMContentLoaded", function () {
  console.log("DOM fully loaded");

  // Cocoonが新しいフォームを追加した直後に呼ばれるイベント
  document.addEventListener("cocoon:after-insert", function (e) {
    console.log("フォームが追加されました", e.target);
  });

  // Cocoonがフォームを削除した直後に呼ばれるイベント
  document.addEventListener("cocoon:after-remove", function (e) {
    console.log("フォームが削除されました", e.target);
  });
});