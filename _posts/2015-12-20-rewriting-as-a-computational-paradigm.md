---
layout: post
title: Rewriting as a Computational Paradigm
custom_js:
# - shuffle
draft: false
---
There are all sorts of ways of getting a computer to compute.
For many programmers, the most natural way is using an [imperative-style language](http://en.wikipedia.org/wiki/Imperative_programming) (e.g., C, Java, Python), where you lay out the exact steps of *how* computation should take place---do this, then this, then this.
In contrast, the [declarative languages](http://en.wikipedia.org/wiki/Declarative_programming) generally focus less on how computation should take place and instead focus more on *what* the computation should do.
In writing declarative programs, one describes the goals of computation without describing the exact steps---a function that computes so-and-so should have such and such properties.

The most popular kinds of declarative languages these days are the [functional languages](http://en.wikipedia.org/wiki/Functional_programming) (e.g., OCaml, Haskel, Lisp), which make it easy to build expressions describing facts (as opposed to statements describing actions).
However, there are other kinds of declarative paradigms focusing on [logical deduction](https://en.wikipedia.org/wiki/Logic_programming) (e.g., Prolog) or [data query](https://en.wikipedia.org/wiki/Query_language) (e.g., SQL, XQuery, XSLT).
One of the fringe arms on the constellation of declarative languages are the [rewriting](https://en.wikipedia.org/wiki/Rewriting) languages.

In rewriting languages, the state of a running program is generally a *thing* (a string, a tree, an expression) that gets transformed during each step of computation to another *thing*.
There are string rewriting languages, term rewriting languages, graph rewriting languages, etc.
I personally find rewriting to be expressive and intuitive, and so I want to share the basic ideas with people who might be interested in learning a new paradigm.
We will take a brief look at string rewriting languages, followed by term rewriting languages.

## String Rewriting (A Warmup!)

The simplest kind of [Turing-complete](https://en.wikipedia.org/wiki/Turing_completeness) rewriting languages are the [string rewriting](https://en.wikipedia.org/wiki/Semi-Thue_system) languages.
In a string rewriting language, the input (and state) of a running program is a string.
The programmer writes a set of rules that describe how substrings should be rewritten into other strings.
Each replacement transforms the string, which may enable other rules to apply, and so on.

String rewriting is not something that's really used for general purpose programming.
We are looking at it here to get an idea for the basics of using rewriting as a computational device.

### An Example String Rewriting Language

Let's make up our own string-rewriting language (basically a sublanguage of [Thue](http://esolangs.org/wiki/thue)) with rules arranged like (LHS &rArr; RHS).
The left-hand-side (LHS) of a rule is a pattern (substring) to be matched, and if a match is found, it can be replaced with the right-hand-side (RHS) of the rule.
Using these rules, each step of computation takes the following shape: match the LHS (left-hand side) of a rule as a substring in the current state and replace it with the RHS (right-hand side); repeat until no rules apply.
In our string rewriting language, there will be no special characters---all characters are meant to be literal characters.

Now that we have a string-rewriting language, let's write a program.
Let's say you want to increment a binary number that is given to you as a string delimited with underscores.
E.g., you'd like a program that takes in "\_1011\_" as input and returns as output "\_1100".
Here is a program to do so:
<pre>
# get started
1_ &rArr; 1++      [Rule1]
0_ &rArr; 1        [Rule2]

# eliminate ++
01++ &rArr; 10     [Rule3]
11++ &rArr; 1++0   [Rule4]
_1++ &rArr; _10    [Rule5]
</pre>

In this program, we use <code>++</code> as a marker for "increment what's to the left of this marker".
Computation on our example input proceeds through the following program states:
<table>
	<tr><th>String</th><th>Reasoning</th></tr>
	<tr><td><code>_1011_</code></td><td>Input</td></tr>
	<tr><td><code>_1011++</code></td><td>by applying Rule1</td></tr>
	<tr><td><code>_101++0</code></td><td>Rule4</td></tr>
	<tr><td><code>_1100</code></td><td>Rule3</td></tr>
</table>

Try extending the above program to eliminate the left-most underscore.
As a harder exercise, try writing a program that adds two strings (e.g., "101+11" gets transformed to "1000").
It should be pretty clear how writing programs for a string rewriting language is similar to writing programs for a [Turing machine](https://en.wikipedia.org/wiki/Turing_machine).

This is a pretty inexpressive language, though we can imagine extending this language with variable capture (like regex capture groups), input/output, etc.
Generally speaking, rewriting can be nondeterministic, so you can have rules that compete:
<pre>
0 &rArr; a
0 &rArr; b
</pre>
All together, a pretty interesting regex-style language could be made from these components.

### <a name="traversal"></a> What Does Rewriting Afford Us? 

At first glance, rewriting doesn't appear to be any different from pattern matching in functional languages.
In some sense, this is true---you get to match things and replace them with other things.
However, because rewriting rules match anywhere they can, in whatever order they can, it frees the programmer from having to worry about traversing objects or ordering lists of rules or how rules might be applied concurrently.
Of course, actual implementations of rewriting languages will have some strategies (simple or complicated) for applying rules, but as long as the programmer focuses on making individual steps that make progress, everything works out.

To really hammer the idea home, let's go ahead and write a concrete implementation of the above rules in a functional language.
It will be pretty obvious how to generate this code based on a set of rules.
We have to pick a traversal mechanism to search a string for matches (let's choose left-to-right), and an ordering for rules to apply (let's choose top-to-bottom, starting at the top every time a match is applied).
Here's how it might look in OCaml:
{% highlight OCaml %}
(* try to apply any rule; returns the result string (perhaps with changes),
   together with a bool representing if any rules actually applied *)
let rec rewriteOnce (l : char list) : char list * bool =
	match l with
	(* here we encode the five rules as cases against char lists *)
	| '1' :: '_' :: xs               -> '1' :: '+' :: '+' :: xs, true
	| '0' :: '_' :: xs               -> '1' :: xs, true
	| '0' :: '1' :: '+' :: '+' :: xs -> '1' :: '0' :: xs, true
	| '1' :: '1' :: '+' :: '+' :: xs -> '1' :: '+' :: '+' :: '0' :: xs, true
	| '_' :: '1' :: '+' :: '+' :: xs -> '_' :: '1' :: '0' :: xs, true
	(* if we don't see a match at the beginning of the string,
	   ignore the first character and recurse *)
	| x :: xs                        -> let s, b = rewriteOnce(xs) in x :: s, b
	(* if we make it all the way to the end of a string,
	   then we failed to match any rules and computation has terminated *)
	| []                             -> [], false
;;

(* keep trying to apply rules until no more rules apply *)
let rec rewriteMany (l : char list) : char list =
	let l, tookStep = rewriteOnce l in 
		if tookStep then rewriteMany l else l
;;

let rewrite (s : string) : string =
	let s = rewriteMany (explode s) in implode s
;;
{% endhighlight %}

Implementations of the helper functions <code>explode</code> and <code>implode</code> can be found [here](http://caml.inria.fr/pub/old_caml_site/FAQ/FAQ_EXPERT-eng.html#strings).
In OCaml, strings can't be pattern matched against directly---they must be converted to <code>char list</code>s first.

Again, this is just one of many possible implementations of a string rewriting language.
It might be that applying the rules in different orders result in different outcomes (as in the nondeterminism example above), or more efficient chains of computation.
As written, this would be a terribly inefficient implementation.
One improvement would be to keep indexes to track which rules are enabled after each step.
Leaving such decisions up to the implementation frees the programmer from having to worry about them; one is left with deciding how states should be transformed into other states.

Now that we've covered the basics in a toy language, let's move on to a real rewriting language.

## Term Rewriting

Term rewriting has been used as the basis of a number of general purpose programming languages such as 
[Clean](https://en.wikipedia.org/wiki/Clean_(programming_language)),
[Maude](https://en.wikipedia.org/wiki/Maude_system),
[Pure](https://en.wikipedia.org/wiki/Pure_(programming_language)),
[Rascal](https://en.wikipedia.org/wiki/RascalMPL),
[Stratego/XT](https://en.wikipedia.org/wiki/Stratego/XT),
and [Tom](https://en.wikipedia.org/wiki/Tom_(pattern_matching_language)).
We will be doing all of our examples in Maude, because it is the language I'm most familiar with.
It is also, arguably, one of the most expressive and efficient languages of the bunch.

In term rewriting languages, terms (syntax trees) are the basic unit of state.
A program consists of rules that match subterms and replace them with new subterms.
Unlike our simple string rewriting example, term rewriting languages generally have complex [pattern matching](https://en.wikipedia.org/wiki/Pattern_matching) with variable binding, types, and even rewriting in the presence of equational theories.
Each of these will be touched on in the examples below.

### Arithmetic

To get us started with a simple example, let's see how we might encode numbers and perform arithmetic in a term rewriting language.
Of course, numbers and arithmetic are builtin to most languages; we're only using it as a convenient example.

#### Syntax
Because we're talking about *term*-rewriting, we need a way to define what terms are allowed.
This is like describing a syntax that we're going to allow ourselves to talk about.
Natural numbers are built recursively using the following [signature](http://en.wikipedia.org/wiki/Signature_(logic)):

<pre>
sort Nat .

op 0 : -> Nat .
op s(_) : Nat -> Nat .
</pre>

This says that we're defining a new sort (thing, type) "<code>Nat</code>".
We can build up <code>Nat</code>s in two ways: <code>0</code> is a <code>Nat</code>, and <code>s</code> (successor) is an operator taking <code>Nat</code> arguments and resulting in a <code>Nat</code>.

In [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_Form), the above would be written as
<pre>
&lt;Nat> ::= "0"
        | "s(" &lt;Nat> ")"
</pre>

This grammar lets us construct different <code>Nat</code>s like <code>0</code>, <code>s(0)</code>, <code>s(s(0))</code>, etc.
Intuitively, we want the term <code>0</code> to correspond to the number 0, <code>s(0)</code> to correspond to 1, <code>s(s(0))</code> to correspond to 2, etc.
As a reminder, Maude has actual built-in numbers; we're just using this as a simple example.

Let's add some syntax that lets us write basic arithmetic expressions:
<pre>
op _+_ : Nat Nat -> Nat .
op _*_ : Nat Nat -> Nat .
</pre>

Now we can construct terms like <code>s(s(s(0))) * (s(s(0)) + s(0))</code>, intuitively representing 3 * (2 + 1).[^parens]

[^parens]: The astute reader will notice we never added a <code>(_)</code> production for grouping; Maude allows parens for disambiguating ambiguous parsings.

#### Addition

Okay, so far all we've done is declare some syntax.
How do we actually do computation with the terms we can express?
Let's write some rewrite rules to define addition:
<pre>
eq N:Nat + 0 = N:Nat .                    [Rule1]
eq N:Nat + s(M:Nat) = s(N:Nat + M:Nat) .  [Rule2]
</pre>

Rule1 is pretty straightforward---if we're adding two numbers and the second number is a 0, then the result of the addition is just the first number.
Rule2 moves the <code>s</code> symbol from the second argument of an addition to surround the addition itself.
This way, the right argument of an addition eventually becomes <code>0</code>.
To see how this works, here's how the previous two rules would apply to <code>s(s(s(0))) + s(s(0))</code>:
<table>
	<tr><th>Step</th><th>Term</th><th>Reasoning</th></tr>
	<tr>
		<td>0</td>
		<td><code>s(s(s(0))) + s(s(0))</code></td>
		<td>Input</td>
	</tr>
	<tr>
		<td rowspan="2">1</td>
		<td><code><span class="maudeContext"><span class="maudeStep1">s(s(s(0)))</span> + s(<span class="maudeStep1">s(0)</span>)</span></code></td>
		<td>Match Rule2 with <code>N</code> = <code><span class="maudeStep1">s(s(s(0)))</span></code> and <code>M</code> = <code><span class="maudeStep1">s(0)</span></code></td>
	</tr>
	<tr>
		<td><code><span class="maudeContext">s(<span class="maudeStep1">s(s(s(0)))</span> + <span class="maudeStep1">s(0)</span>)</span></code></td>
		<td>Apply Rule2</td>
	</tr>
	<tr>
		<td rowspan="2">2</td>
		<td><code>s(<span class="maudeContext"><span class="maudeStep2">s(s(s(0)))</span> + s(<span class="maudeStep2">0</span>)</span>)</code></td>
		<td>Match Rule2 with <code>N</code> = <code><span class="maudeStep2">s(s(s(0)))</span></code> and <code>M</code> = <code><span class="maudeStep2">0</span></code></td>
	</tr>
	<tr>
		<td><code>s(<span class="maudeContext">s(<span class="maudeStep2">s(s(s(0)))</span> + <span class="maudeStep2">0</span>)</span>)</code></td>
		<td>Apply Rule2</td>
	</tr>
	<tr>
		<td rowspan="2">3</td>
		<td><code>s(s(<span class="maudeContext"><span class="maudeStep3">s(s(s(0)))</span> + 0</span>))</code></td>
		<td>Match Rule1 with <code>N</code> = <code><span class="maudeStep3">s(s(s(0)))</span></code></td>
	</tr>
	<tr>
		<td style="display:none"></td>
		<td><code>s(s(<span class="maudeContext"><span class="maudeStep3">s(s(s(0)))</span></span>))</code></td>
		<td>Apply Rule1</td>
	</tr>
</table>
As in string rewriting, in each step we look for a place where the left-hand side of a rule matches a subterm.
In the table above, I've emphasized this location by using a thin, rectangular border around the subterm.
In step 1, the matched term is the entire term.
In step 2, the matched term is a proper subterm---it is the child of an outer <code>s(_)</code> term.
In step 3, the matched term is a subterm of an outer <code>s(s(_))</code> term.
Once we find a match, we transform it into the right-hand side of the rule.

We can get Maude to reduce this term for us by saying:
<pre>
red s(s(s(0))) + s(s(0)) .
</pre>
<pre>
result Nat: s(s(s(s(s(0)))))
</pre>

Try to convince yourself that these are the only rules needed to defined addition over natural numbers.

#### More Operations
Multiplication can be computed as follows:
<pre>
eq N:Nat * 0 = 0 .
eq N:Nat * s(M:Nat) = (N:Nat * M:Nat) + N:Nat .
</pre>
We could keep adding operators like this all day, but let's stop after one more:
<pre>
op _<_ : Nat Nat -> Bool .
eq 0 < s(N:Nat) = true .
eq N:Nat < 0 = false .
eq s(N:Nat) < s(M:Nat) = N:Nat < M:Nat .
</pre>
Maude has conditional rules, which allow you an alternate way to express the first equation:
<pre>
ceq 0 < N:Nat = true  if N:Nat =/= 0 .
</pre>
In the case that the side condition holds, a conditional rule applies as a normal rule would.

#### Comparison with Functional
How would we define the above encoding of natural numbers in a functional language?
The most obvious way (done here in OCaml) would be as follows:
{% highlight OCaml %}
type nat =
	| Zero
	| Succ of nat
;;

let rec plus x y =
	match y with
	| Zero -> x
	| Succ n -> Succ(plus x n)
;;
{% endhighlight %}
Here, <code>Zero</code> and <code>Succ</code> make up a new datatype <code>nat</code>, and we define a function <code>plus</code> taking <code>nat</code>s to <code>nat</code>s.
However, in rewriting, there are no functions like this <code>plus</code>---the <code>_+_</code> operator is just another way to build terms.
This might seem like a pedantic distinction, but one can take advantage of it when writing programs.
Imagine a new operator for pretty-printing terms:
<pre>
op describe(_) : Nat -> String .
eq describe(0) = "zero" .
eq describe(s(N:Nat)) = "s(" + describe(N:Nat) + ")" .
eq describe(N:Nat + M:Nat) = "(" + describe(N:Nat) + " + " + describe(M:Nat) + ")" .
</pre>
In most languages, being able to grab the addition operator in this manner would require some kind of reflection or meta-programming capabilities.
In term rewriting, <code>_+_</code> is just another way of building terms, no different from <code>0</code> or <code>s(_)</code>.
Of course, the evolution of a term like <code>describe(0 + 0)</code> is nondeterministic---it could either turn into <code>"0"</code> or <code>"0 + 0"</code>.
For <code>describe</code> to work unambiguously, you'd need to disable the normal rules for <code>_+_</code> or set rule priorities.

In order to allow the possibility of "grabbing" the addition operator in the functional world, you'd need to add a <code>Plus</code> variant to the type.
In order to actually evaluate addition, we'd now have to add a new function, perhaps called "simplify", that would reduce a term to its simplest form.
The <code>simplify</code> function would have to implement a traversal over the term, which we alluded to in a [previous section](#traversal).
We can see what this might look like by taking it one step:
{% highlight OCaml %}
let rec simplifyOnce n =
	match n with
	| Zero -> Zero
	| Plus(x, Zero) -> x
	| Plus(x, (Succ y)) -> Succ (Plus(x, y))
;;
{% endhighlight %}
This <code>simplifyOnce</code> function plays the same role that the <code>rewriteOnce</code> function did for string rewriting.
Every time you added a new way to produce naturals (e.g., multiplication), you'd have to add cases in the traversal.
Not only that, but to make this kind of execution fast is tricky---luckily Maude handles it all for us.

### Lists
Let's graduate to more traditional example programs---the list data type and associated operations.

#### Cons Lists
Let's start with [cons lists](https://en.wikipedia.org/wiki/Cons), the kinds of lists that are typically associated with functional languages.
<pre>
sort ConsList .
op nil : -> ConsList .
op _::_ : Int ConsList -> ConsList .

op head(_) : ConsList -> Int .
eq head(X:Int :: L:ConsList) = X:Int .
op tail(_) : ConsList -> ConsList .
eq tail(X:Int :: L:ConsList) = L:ConsList .

op reverse(_) : ConsList -> ConsList .
op reverseAux(_,_) : ConsList ConsList -> ConsList .
eq reverse(L:ConsList) = reverseAux(L:ConsList, nil) .
eq reverseAux(nil, L:ConsList) = L:ConsList .
eq reverseAux(X:Int :: L:ConsList, L':ConsList) 
   = reverseAux(L:ConsList, X:Int :: L':ConsList) .
</pre>
Not a whole lot of surprises here; these definitions would feel at home in a typical functional language.

#### Real Lists
Although the lists above work, Maude allows the programmer to specify a richer kind of list:
<pre>
sort List .
subsort Int < List .

op nil : -> List .
op _;_ : List List -> List [assoc id: nil] .
</pre>
The <code>[assoc]</code> annotations tells Maude that the operator (<code>_;_</code>) is associative, so that the parse trees <code>(2 ; (3 ; 5))</code> should be considered equivalent to <code>((2 ; 3) ; 5)</code>.
Without telling it otherwise, Maude doesn't know how to parse <code>(2 ; 3 ; 5)</code> unambiguously, and will simply choose a parsing.
The <code>[id: nil]</code> annotation tells Maude that the <code>nil</code> operator is the identity element for the <code>_;_</code> operator.
These annotations are essentially equivalent to the following equations:
<pre>
--- associativity
eq L1:List ; (L2:List ; L3:List) = (L1:List ; L2:List) ; L3:List .
eq (L1:List ; L2:List) ; L3:List = L1:List ; (L2:List ; L3:List) .

--- identity
eq L:List ; nil = L:List .
eq nil ; L:List = L:List .
eq L:List => L:List ; nil .
eq L:List => nil ; L:List .
</pre>
However, such equations would result in nontermination, if actually used.
With the annotation, Maude just knows that they're true and applies them in the case that it enables other rules to apply.
This is what is meant by rewriting in the presence of equational theories, or rewriting "modulo" theories.

Suddenly, writing rules involving lists becomes a lot easier:
<pre>
eq reverse(nil) = nil .
eq reverse(I:Int ; L:List) = reverse(L:List) ; I:Int .
</pre>
Because Maude knows the identity element is <code>nil</code>, it allows the above definition to reduce even <code>reverse(7)</code>.
This is the same as <code>reverse(7 ; nil)</code>, after which the second and then first rule applies.
Generally speaking, such lists are a lot more natural than cons-lists.[^listGotchas]

[^listGotchas]: Though there are some gotchas.  For example, the rule <code>eq reverse(L:List ; L':List) = reverse(L':List) ; reverse(L:List)</code> would cause nontermination.  Given a term like <code>reverse(nil)</code>, Maude can always apply this rule by first expanding the term to <code>reverse(nil ; nil)</code>.  After applying the rule, and another two expansions, it's now ready to apply the rule again twice!


Sorting such lists can be enabled with a single, simple rule:
<pre>
ceq I1:Int ; I2:Int = I2:Int ; I1:Int if I2:Int < I1:Int .
</pre>
Were it not for the <code>[assoc]</code> annotation, this rule would be unable to sort a list like <code>3 ; (2 ; 5)</code>, because the rule would not be able to match.
In most functional languages, it would be difficult to define sorting so succinctly.


### Sets
Sets are where Maude really starts to shine.

<pre>
sort Set .
subsort Int < Set .

op empty : -> Set .
op _,_ : Set Set -> Set [assoc comm id: empty] .
eq I:Int , I:Int = I:Int .
</pre>
The new <code>[comm]</code> annotation tells Maude that the operator is commutative, so that its elements can be rearranged at will.
The equation eliminates duplicates (otherwise, we'd be defining a multi-set).

Let's define an operator for checking if an item exists in a set:
<pre>
op _in_ : Int Set -> Bool .
eq I:Int in empty = false .
eq I:Int in (S:Set , I:Int) = true .
ceq I:Int in (I':Int , S:Set) = I:Int in S:Set
    if I:Int =/= I':Int .
</pre>

The possibility of lists, sets, and multisets (associative and/or commutative operators), coupled with the underlying "let rules match wherever they can" idea, makes for a powerful combination.
It means in a potentially large program state, only the relevant parts need to be matched and manipulated.

### Trees
To round out the examples, let's take a look at how one might describe and write algorithms for tree structures.
<pre>
sort BinTree .

op empty : -> BinTree .
op _[_]_ : BinTree Int BinTree -> BinTree .
</pre>

Traversals can be defined in a straightforward way:
<pre>
op inorder(_) : BinTree -> List .
eq inorder(empty) = [] .
eq inorder(L:BinTree [I:Int] R:BinTree)
   = inorder(L:BinTree) ; I:Int ; inorder(R:BinTree) .

op preorder(_) : BinTree -> List .
eq preorder(empty) = [] .
eq preorder(L:BinTree [I:Int] R:BinTree)
   = I:Int ; preorder(L:BinTree) ; preorder(R:BinTree) .
</pre>

Even keeping the trees sorted (turning them into binary search trees) can be done with two simple, declarative rules:
<pre>
ceq (T1:BinTree [I1:Int] T2:BinTree) [I2:Int] T3:BinTree
    = (T1:BinTree [I2:Int] T2:BinTree) [I1:Int] T3:BinTree
    if I1:Int > I2:Int .
ceq T1:BinTree [I1:Int] (T2:BinTree [I2:Int] T3:BinTree)
    = T1:BinTree [I2:Int] (T2:BinTree [I1:Int] T3:BinTree)
    if I1:Int > I2:Int .
</pre>
The above two rules keeps trees sorted by swapping when necessary.

## Wrapping Up

Rewriting is a special kind of declarative style used in programming languages.
It lets the programmer focus on making small transformations to the program state.
Programs written in a rewriting style are simply collections of such transformations, and execution is the continued application of such rules.

In the interest of conveying the big picture, I've left out many details.
If you're interested in learning more about Maude, there are a few tutorials ([here](http://maude.cs.uiuc.edu/maude1/tutorial/), [here](http://www.cs.swan.ac.uk/~csneal/MaudeCourse/index.html)), though they probably need to be supplemented with information from the [manual](http://maude.cs.illinois.edu/w/index.php?title=Maude_Manual_and_Examples).
With that said, Maude has plenty of shortcomings.
Although it is relatively fast, considering its level of expressivity, it lacks many things necessary for a general purpose programming language (like proper I/O support).
Many of the problems of Maude have been addressed in the [K Framework](http://www.kframework.org/index.php/Main_Page), a domain specific language (based on rewriting) for defining programming languages.
Although first and foremost a language for defining programming languages, it can also been used for general computational problems.
I have only limited experience with other term rewriting languages, but my understanding is that Rascal is probably the most practical, and also the most multi-paradigm.

Pattern matching can be very powerful, and even the rich kinds we saw here are fairly straightforward.
My hope is that language features based on rewriting might find their way into more and more languages or domains.
For general purpose languages, I think all that's needed is to round off some of the rough edges found in the currently existing languages---many started as academic or experimental languages.
For special purpose languages, I'd love to see a shell or sysadmin tool based on rewriting for working with lines, files, and directories.
Let me know if you can think of other kinds of uses for rewriting!
