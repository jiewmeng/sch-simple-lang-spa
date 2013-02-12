# `simple-lang` SPA (Static Program Analyzer)

A personal try for a school project. The aim is to create a SPA that analyzes a SIMPLE (simplified programming language) program. 

**NOTE:** There are probably much better tools to analyze a program than this, ... its a school project after all (for a software engineering module, feels much like a programming language module tho ...)

For the project, we are supposed to use Visual C/C++ 2010 (not even the latest 2012 which is already available) ... here, I will use [CoffeeScript][coffeescript] (JavaScript precompiler) with [PEG.js][pegjs] as a parsing library

## SIMPLE Syntax

A simplified programming language the SPA will analyze

### Concrete Syntax Grammar

#### Meta Symbols

	a*               0 or more times of a
	a+               1 or more times of a
	a | b            a OR b
	brackets ()      grouping

#### Lexical tokens

	LETTER       A-Z a-z
	DIGIT        0-9
	NAME         LETTER (LETTER | DIGIT)*
	INTEGER      DIGIT+

#### Concrete Syntax Grammar

	program         procedure+
	procedure       'procedure' proc_name '{' stmtList '}'
	stmtList        stmt+
	stmt            call | while | if | assign
	call            'call' proc_name ';'
	while           'while' var_name '{' stmtList '}'
	if              'if' var_name '{' stmtList '}' 'else' '{' stmtList '}'
	assign          'var_name' '=' expr ';'
	expr            expr '+' term | expr '-' term | term
	term            term '*' factor | factor
	factor          var_name | const_value | '(' expr ')'
	var_name        NAME
	proc_name       NAME
	const_value     INTEGER

## PQL (Program Query Language) Syntax

The query language (similar to SQL) for developers to query/learn more about the program

**Typical query** looks like 

	Select ... such that ... with ... pattern ...

### PQL Grammar

#### Lexical rules

*Similar to SIMPLE except ...*

	IDENT: LETTER (LETTER | DIGIT | '#')*

#### Auxillary grammar rules

	tuple           elem | '<' elem (',' elem)* '>'
	elem            synonym | attrRef
	synonym         IDENT
	attrName        'procName' | 'varName' | 'value' | 'stmt#'
	entRef          synonym | '_' | '"' IDENT '"' | INTEGER
	stmtRef         synonym | '_' | INTEGER
	lineRef         synonym | '_' | INTEGER
	design-entity   'procedure' | 'stmtLst' | 'stmt' | 'assign' | 'call' | 
	                'while' | 'if' | 'variable' | 'constant' | 'prog_line'

#### Grammar for `Select`

	select-cl         declaration* 'Select' result-cl 
	                  ( suchthat-cl | with-cl | pattern-cl )*
	declaration       design-entity synonym (',' synonym)* ';'
	result-cl         tuple | 'BOOLEAN'
	  
	with-cl           'with' attrCond
	suchthat-cl       'such that' relCond
	pattern-cl        'pattern' patternCond
	  
	attrCond          attrCompare ('and' attrCompare)*
	attrCompare       ref '=' ref
	                  // LHS and RHS should have same type (eg. INTEGER)
	attrRef           synonym '.' attrName
	ref               attrRef | synonym | '"' IDENT '"' | INTEGER
	                  // synonym should be of type `prog_line`
	  
	relCond           relRef ('and' relRef)*
	relRef            ModifiesP | ModifiesS | UsesP | UsesS | Calls | 
	                  CallsT | Parent | ParentT | Follows | FollowsT | 
	                  Next | NextT | Affects | AffectsT
	ModifiesP         'Modifies' '(' entRef ',' entRef ')'
	ModifiesS         'Modifies' '(' stmtRef ',' entRef ')'
	UsesP             'Uses' '(' entRef ',' entRef ')'
	UsesS             'Uses' '(' stmtRef ',' entRef ')'
	Calls             'Calls' '(' entRef ',' entRef ')'
	CallsT            'Calls*' '(' entRef ',' entRef ')'
	Parent            'Parent' '(' stmtRef ',' stmtRef ')'
	ParentT           'Parent*' '(' stmtRef ',' stmtRef ')'
	Follows           'Follows' '(' stmtRef ',' stmtRef ')'
	FollowsT          'Follows*' '(' stmtRef ',' stmtRef ')'
	Next              'Next' '(' lineRef ',' lineRef ')'
	NextT             'Next*' '(' lineRef ',' lineRef ')'
	Affects           'Affects' '(' stmtRef ',' stmtRef ')'
	AffectsT          'Affects*' '(' stmtRef ',' stmtRef ')'
	  
	patternCond       pattern ('and' pattern)
	pattern           assign | while | if
	assign            synonym '(' entRef ',' expression-spec | '_' ')'
	expression-spec   '"' expr '"' | '_' '"' expr '"' '_'
	if                synonym '(' entRef ',' '_' ',' '_' ')'
	while             synonym '(' entRef ',' '_' ')'

### PQL Design Abstractions

Unless otherwise stated: 

- `p | q` - procedures
- `a` - assignment
- `v` - variable
- `s` - statement
- `n` - statement number 

#### Calls

- `Calls(p, q)` holds if `p` directly calls `q`
- `Calls*(p, q)` holds if `p` directly/indirectly calls `q`
    - `Calls(p, q)` OR
    - `Calls(p, p1)` AND `Calls*(p1, q)`

#### Modifies

- `Modifies(a, v)` if `v` appears on LHS of `a`
- `Modifies(s, v)` where `s` is a container statement (`if | while`) holds if theres a statement `s1` such that `Modifies(s1, v)` holds
- `Modifies(p, v)` if theres a `s` in `p` or in `p1` called directly/indirectly such that `Modifies(s, v)` holds
- If `s` is a procedure call, its defined the same as `Modifies(p, v)` 

#### Uses

- `Uses(a, v)` if `v` appears on RHS of `a`
- `Uses(s, v)` where `s` is a container statement (`if | while`) holds if `v` is used as a control variable or theres a statement `s1` such that `Uses(s1, v)` holds
- `Uses(p, v)` if theres a `s` in `p` or in `p1` called directly/indirectly such that `Uses(s, v)` holds
- If `s` is a procedure call, its defined the same as `Uses(p, v)`

#### Parent 

- `Parent(s1, s2)` if `s2` is directly nested inside `s1`
	- `s1, s2` must be container statements
- `Parent*(s1, s2)` if 
	- `Parent(s1, s2)` OR
	- `Parent(s1, s)` AND `Parent*(s, s2)`

#### Follows 

- `Follows(s1, s2)` if `s2` appears directly after `s1` in same nesting level
	- `s1, s2` must be container statements
- `Follows*(s1, s2)` if 
	- `Follows(s1, s2)` OR
	- `Follows(s1, s)` AND `Follows*(s, s2)`

#### Next

- `Next(n1, n2)` if 
	- `n1, n2` are in same procedure
	- `n2` can be executed immediately after n1 in some program execution sequence
- `Next*(n1, n2)` if 
	- `Next(n1, n2)` OR
	- `Next(n1, n)` AND `Next*(n, n2)`

#### Affects

- `Affects(a1, a2)` if 
	- `a1, a2` are in same procedure
	- `a1` modifies `v` AND `a2` uses `v`
	- there is a control flow path from `a1` to `a2`, such that `v` is not modified in any assignment/procedure called in path
- `Affects*(a1, a2)` if 
	- `Affects(a1, a2)` OR
	- `Affects(a1, a)` AND `Affects*(a, a2)`




[coffeescript]: http://coffeescript.org/
[pegjs]: http://pegjs.majda.cz/