start
= procedure+

procedure
= "procedure" space* name:identifier space* stmtList:stmtList space*
{ return { type: "procedure", name: name, stmtList:stmtList } }

identifier
= identifier:([a-zA-Z][a-zA-Z0-9]*)
{ 
	var letters = identifier[0];
	identifier[1].forEach(function(letter) {
		letters += letter;
	});
	return letters;
}

space 
= [ \t\n\r] 
{ return "" }

stmtList
= "{" space* stmtList:stmt* space* "}"
{ return stmtList }

stmt
= space* stmt:(assign / while / if / call)
{ return stmt }

assign
= lhs:identifier space* "=" space* rhs:expr space* ";"
{ return { type: "assign", lhs: lhs, rhs: rhs } }

while 
= space* "while" space* control:identifier space* stmtList:stmtList space*
{ return { type: "while", control: control, stmtList: stmtList } }

if 
= space* "if" space* control:identifier space* "then" space* ifBranch:stmtList space* "else" space* elseBranch:stmtList space*
{ return { type: "if", ifBranch: ifBranch, elseBranch: elseBranch } }

call
= space* "call" space* procName:identifier space* ";"
{ return { type: "call", procName: procName } }

expr
= additive

additive
= left:multiplicative _ tail:([+-] _ multiplicative)* 
{
  tail.forEach(function(value) {
    // value[0] is sign
    // value[2] is multiplicative rule result (our value)
    left.push({ type: "operator", value: value[0] });
    left = left.concat( value[2] );
  });
  return left;
}

multiplicative
= left:unary _ tail:([*/%] _ unary)* 
{
  tail.forEach(function(value) {
    // value[0] is sign
    // value[2] is multiplicative rule result (our value)
    left.push({ type: "operator", value: value[0] });
    left = left.concat( value[2] );
  });
  if (left.length == 1) 
    return left;
  return [ left ];
}

unary
= sign:[+-]? _ value:primary _ 
{
  var tmp = [];
  if (sign) {
    tmp.push({ type: "operator", value: sign }); 
  } else if (value instanceof Array) {
    return value;
  }
  tmp.push(value);
  return tmp;
}

primary
= integer
/ variable
/ "(" additive:additive ")" { return additive; }

variable
= variable:([a-zA-Z][a-zA-Z0-9]*)
{ 
  return {
    type: "variable",
    value: variable[0] + variable[1].join("")
  };
}

integer "integer"
= digits:[0-9]+ 
{ 
  return {
    type: "integer",
    value: digits.join("") 
  };
}

_ "whitespace"
= [ \n\r]*