(async()=>{
const picker=document.getElementById("language");
if(!picker)return;
let languages;
try{const response=await fetch("/locales",{credentials:"same-origin"});if(!response.ok)return;languages=await response.json()}catch{return}
if(!Array.isArray(languages)||!languages.length)return;
const known=new Map(languages.map(item=>[item.code,item.name]));
for(const [code,name] of known){const option=document.createElement("option");option.value=code;option.textContent=name;picker.append(option)}
const browser=[...(navigator.languages||[]),navigator.language||"en"];
const browserLanguage=()=>{for(const tag of browser){const value=String(tag).toLowerCase();if(known.has(value))return value;const base=value.split("-")[0];if(known.has(base))return base}return "en"};
let stored="auto";
try{stored=localStorage.getItem("quirea.language")||"auto"}catch{}
if(stored!=="auto"&&!known.has(stored))stored="auto";
picker.value=stored;
async function render(){
const language=picker.value==="auto"?browserLanguage():picker.value;
let data;
try{const response=await fetch(`/locales/${encodeURIComponent(language)}.json`,{credentials:"same-origin"});if(!response.ok)return;data=await response.json()}catch{return}
if(!data||typeof data.messages!=="object"||data.messages===null)return;
for(const node of document.querySelectorAll("[data-i18n]")){const key=node.getAttribute("data-i18n");if(typeof data.messages[key]==="string")node.textContent=data.messages[key]}
document.documentElement.lang=language;
const automatic=picker.querySelector('option[value="auto"]');if(automatic&&typeof data.messages.automatic==="string")automatic.textContent=data.messages.automatic;
}
picker.addEventListener("change",()=>{try{localStorage.setItem("quirea.language",picker.value)}catch{}void render()});
await render();
})();
