function reverse(string: any) {
  return string.split("").reverse().join("");
}

const originString = "hello";
const reversed = reverse(originString);

function checkIsPalinDrome(string: any) {
  const strCleaned = string.toLowerCase();
  const strReversed = reverse(strCleaned);
  return strCleaned == strReversed;
}
console.log(checkIsPalinDrome("A man, a plan, a canal: Panama"));
