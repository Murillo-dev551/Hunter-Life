const fs=require('fs');
const root='assets/icons/';
const choices={accept:'<path d="m2 11 5-5 6 1 5-1 5 5-4 9-6 4-8-8-3-5Zm5-5 7 5-4 4-3-2m6 0 8 6M2 11l4 4m17-4-4 4"/>',talk:'<path d="M3 5h20v15H12l-7 5v-5H3Z"/><circle cx="8" cy="12" r="1"/><circle cx="13" cy="12" r="1"/><circle cx="18" cy="12" r="1"/>',back:'<path d="M5 22h11a8 8 0 0 0 0-16H4m5-5L4 6l5 5"/>'};
for(const [id,body] of Object.entries(choices))fs.writeFileSync(root+'choice_'+id+'.svg','<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><g fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+body+'</g></svg>\n');
const mark='<path d="M2 4h37l7 7v25H2Z" fill="#243B5A"/><path d="M5 7h32l6 6v20H5Z" fill="#F1E8D7"/><path d="m16 10 7 10-7 10-7-10Z" fill="#963D49"/><path d="m16 14 3 6-3 6-3-6Z" fill="#243B5A"/><path d="M27 14h10M27 20h10M27 26h6" stroke="#243B5A" stroke-width="2"/><path d="m39 4 7 7h-7Z" fill="#963D49"/>';
fs.writeFileSync(root+'emblem.svg','<svg xmlns="http://www.w3.org/2000/svg" width="48" height="40" viewBox="0 0 48 40">'+mark+'</svg>\n');
for(const [id,body] of Object.entries({adventure:'<circle cx="12" cy="12" r="9"/><path d="M12 1v4M12 19v4M1 12h4M19 12h4M16 8l-3 5-5 3 3-5Z"/>',record:'<path d="M12 5C9 3 5 3 2 4v16c4-1 7-1 10 1 3-2 6-2 10-1V4c-3-1-7-1-10 1Zm0 0v16M5 8h4M5 12h4M15 8h4M15 12h4"/>'})){
 fs.writeFileSync(root+id+'.svg','<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="#fff" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">'+body+'</g></svg>\n');
}
fs.writeFileSync(root+'app_icon.svg','<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 192 192"><rect width="192" height="192" fill="#F1E8D7"/><path d="M0 0h192v16H0ZM0 176h192v16H0Z" fill="#243B5A"/><g transform="translate(24 36) scale(3)">'+mark+'</g></svg>\n');
fs.writeFileSync(root+'app_foreground.svg','<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" viewBox="0 0 432 432"><g transform="translate(108 126) scale(4.5)">'+mark+'</g></svg>\n');
fs.writeFileSync(root+'app_background.svg','<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432"><path fill="#F1E8D7" d="M0 0h432v432H0Z"/></svg>\n');
fs.writeFileSync(root+'app_monochrome.svg','<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" viewBox="0 0 432 432"><g transform="translate(108 126) scale(4.5)" fill="none" stroke="#fff" stroke-width="3"><path d="M2 4h37l7 7v25H2Z"/><path d="m16 10 7 10-7 10-7-10ZM27 14h10M27 20h10M27 26h6"/></g></svg>\n');
