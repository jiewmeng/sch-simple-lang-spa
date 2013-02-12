start
= declarations:declaration* space* conditions:selectClause
{ 
	var declarationArr = [];
	declarations.forEach(function(declaration) {
		declaration.forEach(function(synonym) {
			declarationArr.push(synonym);
		});
	});
	return { declarations: declarationArr, conditions: conditions } 
}

declaration
= designEntity:designEntity space* synonym:synonym synonyms:(space* "," space* synonym)* space* ";" space*
{
	var synonymArr = [];
	synonymArr.push({ type: designEntity, synonym: synonym });
	synonyms.forEach(function(item) {
		synonymArr.push({ type: designEntity, synonym: item[item.length-1] });
	});
	return synonymArr;
}

designEntity
= "procedure" / "stmtList" / "stmt" / "assign" / "call" / "while" / "if" / "variable" / "constant" / "prog_line"

synonym
= synonym:([a-zA-Z][a-zA-Z0-9#]*)
{ 
	var synonymStr = "";
	synonymStr += synonym[0];
	synonym[1].forEach(function(letter) {
		synonymStr += letter;
	});
	return synonymStr;
}

selectClause
= "Select" space* queryVars:queryVars space* suchthat:suchthatClauses
{ 
	return {
		queryVars: queryVars,
		suchthat: suchthat
	}
}

queryVars
= "BOOLEAN" { return { type: "boolean" } }
/ tuple

tuple
= elem:elem { return { type: "elem", elem: elem } }
/ "<" space* elem1:elem elems:(space* "," space* elem)* space* ">"
{
	var elemsArr = [];
	elemsArr.push(elem1);
	elems.forEach(function(item) {
		console.log(item);
		elemsArr.push(item[item.length - 1]);
	});
	return { type: "tuple", elems: elemsArr };
}

elem
= synonym:synonym { return { type: "synonym", synonym: synonym } }
/ attrRef:attrRef { return { type: "attrRef", attrRef: attrRef } }

suchthatClause
= modifies
/ uses
/ calls
/ parent
/ follows
/ next
/ affects

suchthatClauses
= "such that" space* cl1:suchthatClause cls:(space* "and" space* suchthatClause)*
{
	var clauses = [];
	clauses.push(cl1);
	cls.forEach(function(cl) {
		clauses.push(cl[cl.length-1]);
	});
	return clauses;
}

modifies 
= "Modifies" space* "(" space* stmtOrEnt:entRef space* "," space* entRef:entRef space* ")"
{ 
	return {
		type: "modifies",
		args: [ stmtOrEnt, entRef ]
	}
}

uses
= "Uses" space* "(" space* stmtOrEnt:entRef space* "," space* entRef:entRef space* ")"
{
	return {
		type: "uses",
		args: [ stmtOrEnt, entRef ]
	}
}

calls
= "Calls" transitive:("*"?) space* "(" space* calleeProc:entRef space* "," space* calledProc:entRef space* ")"
{
	return {
		type: "calls",
		transitive: (transitive ? true : false),
		calleeProc: calleeProc,
		calledProc: calledProc
	}
}

parent
= "Parent" transitive:("*"?) space* "(" space* parent:stmtRef space* "," space* child:stmtRef space* ")"
{
	return {
		type: "parent",
		transitive: (transitive ? true : false),
		parent: parent,
		child: child
	}
}

follows
= "Follows" transitive:("*"?) space* "(" space* before:stmtRef space* "," space* after:stmtRef space* ")"
{
	return {
		type: "follows",
		transitive: (transitive ? true : false),
		before: before,
		after: after
	}
}

next
= "Next" transitive:("*"?) space* "(" space* before:lineRef space* "," space* after:lineRef space* ")"
{
	return {
		type: "next",
		transitive: (transitive ? true : false),
		before: before,
		after: after
	}
}

affects
= "Affects" transitive:("*"?) space* "(" space* affecting:stmtRef space* "," space* affected:stmtRef space* ")"
{
	return {
		type: "affects",
		transitive: (transitive ? true : false),
		affecting: affecting,
		affected: affected
	}
}

stmtRef
= synonym:synonym { return { type: "synonym", value: synonym } }
/ "_" { return { type: "underscore" } }
/ integer:integer { return { type: "integer", value: integer } }

entRef
= synonym:synonym { return { type: "synonym", value: synonym } }
/ "_" { return { type: "underscore" } }
/ integer:integer { return { type: "integer", value: integer } }
/ "\"" ident:synonym "\"" { return { type: "identifier", value: ident } }

lineRef
= synonym:synonym { return { type: "synonym", value: synonym } }
/ "_" { return { type: "underscore" } }
/ integer:integer { return { type: "integer", value: integer } }

attrRef
= synonym "." attrName

attrName
= "procName" / "varName" / "value" / "stmt#"

integer
= digits:([0-9]+)
{ return digits.join("") }

space 
= [ \t\n\r]
{ return "" }