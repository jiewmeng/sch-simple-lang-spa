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

operand
= variable:identifier { return { type: "variable", name: variable } }
/ constant:constant { return { type: "constant", value: constant } }

operator
= space* operator:[+\-*] space*
{ return { type: "operator", value: operator } }

constant
= constant:[0-9]+
{ return constant.join("") }

expr
= operand:operand subexpr:(operator operand)*
{ 
	var tmp = [];
	tmp.push(operand); 
	subexpr.forEach(function(item) { 
		tmp= tmp.concat(item); 
	}); 
	return tmp;
}