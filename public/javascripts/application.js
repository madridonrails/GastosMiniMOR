// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function switchToOpenId(container) {
 showOpenId(container);
 clearUserNameAndPassword(container);
 clearOpenId(container);
}

function swithToUserNameAndPassword(container) {
 hideOpenId(container);
 clearUserNameAndPassword(container);
}

function showOpenId(container) {  
 $A($(container).getElementsByClassName('password_data')).invoke('hide');
 $A($(container).getElementsByClassName('open_id_data')).invoke('show');
}

function hideOpenId(container) {
 $A($(container).getElementsByClassName('password_data')).invoke('show');
 $A($(container).getElementsByClassName('open_id_data')).invoke('hide');
 $A($(container).getElementsByClassName('identity_url')).first().value = "";
}

function clearOpenId(container) {
 var identity_url = $A($(container).getElementsByClassName('identity_url')).first();
 identity_url.value = "";
 identity_url.focus();
}

function clearUserNameAndPassword(container) {
 $A($(container).getElementsByClassName('password')).each(function(password) { password.value = "" });
 // $A($(container).getElementsByClassName('email')).each(function(email) { email.value = "" });
 $A($(container).getElementsByClassName('email')).first().focus();
}