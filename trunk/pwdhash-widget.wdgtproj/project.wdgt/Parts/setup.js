// This file was generated by Dashcode from Apple Inc.
// DO NOT EDIT - This file is maintained automatically by Dashcode.
function setupParts() {
    if (setupParts.called) return;
    setupParts.called = true;
    CreateGlassButton('done', { text: 'Done', onclick: 'showFront' });
    CreateButton('button', { text: 'Generate', onclick: 'hashPassword', rightImageWidth: 5, leftImageWidth: 5 });
    CreateText('domainLabel', { text: 'Domain' });
    CreateText('passwordLabel', { text: 'Password' });
    CreateText('pwdhash', { text: 'Based on pwdhash.com' });
    CreateText('blogUrl', { text: 'http://blog.seagul.co.uk' });
    CreateText('emailAddress', { text: 'chris@seagul.co.uk' });
    CreateInfoButton('infobutton', { foregroundStyle: 'white', frontID: 'front', onclick: 'showBack', backgroundStyle: 'black' });
    CreateText('blogUrl1', { text: unescape('By Me%2C Chris:') });
}
window.addEventListener('load', setupParts, false);