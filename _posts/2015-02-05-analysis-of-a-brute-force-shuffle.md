---
layout: post
title: Analysis of a Brute-Force Shuffle
custom_js:
- shuffle
---

I was reading a [blog post on card shuffling](http://datagenetics.com/blog/november42014/index.html) that described a brute-force card shuffling algorithm.
The algorithm takes 52 cards labeled 1 to 52, in order.
For each card, it throws a 52-sided die and places the card into the deck at the position shown on the die, unless that position was used already.
If the position is already taken, the die is thrown until an unused spot comes up:

<figure>
{% highlight c %}
void brute_shuffle(int deck[static 52]) {
	for (int i = 0; i < 52; i++) {
		deck[i] = 0;
	}
	for (int card = 1; card <= 52; card++) {
		int pos;
		do {
			pos = rand_n(52);
		} while (deck[pos] != 0);
		deck[pos] = card;
	}
}
{% endhighlight %}
<figcaption>Brute-Force Shuffle.</figcaption>
</figure>

This algorithm works and is relatively simple.
In contrast, here is a much fast algorithm ([Fisher-Yates](http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle)) for doing the same thing:

<figure>
{% highlight c %}
void fisher_yates_shuffle(int deck[static 52]) {
	for (int i = 0; i < 52; i++) {
		deck[i] = i + 1;
	}
	for (int i = 52 - 1; i > 0; i--) {
		int s = rand_n(i + 1);
		int temp = deck[s];
		deck[s] = deck[i];
		deck[i] = temp;
	}
}
{% endhighlight %}
<figcaption>Fisher-Yates Shuffle.</figcaption>
</figure>

It's not a whole lot more complicated, although it might be harder to convince yourself that this always results in a properly shuffled deck.

In his post, the author says that the brute-force algorithm is bad.
His presentation made me wonder just how bad.

## Calls to <code>rand_n()</code>

Getting a new random number is probably the most expensive part of these calculations, so let's figure out how many times <code>rand_n()</code> is called in each.

### Brute-force

For the brute-force algorithm, the chances of getting a collision depend on how many of the slots in the deck are already full.
Let's say \\(m\\) of the slots already have cards, and \\(52-m\\) slots are free.
Since the chance of finding a free slot in exactly \\(k\\) calls means getting \\(k-1\\) collisions then succeeding once, the probability is:

$$p(k, m) = \left(\frac{m}{52}\right)^{k-1} \frac{52 - m}{52}$$

We might want to reason about shuffling more than 52 cards, so let's generalize this formula to \\(n\\) cards:

$$p(k, m, n) = \left(\frac{m}{n}\right)^{k-1} \frac{n - m}{n}$$

We can calculate the [expected number](http://en.wikipedia.org/wiki/Expected_value) of calls to <code>rand_n()</code> by adding up all the products of the number of calls \\(k\\) with the probability it took that many calls \\(p(k, m, n)\\):

$$E(m, n) = \sum\limits_{k=1}^\infty k \left(\frac{m}{n}\right)^{k-1} \frac{n - m}{n}$$

Now so far, we've only taken into consideration a particular \\(m\\).  To extend this for all \\(m\\), we add another sum:

$$E(n) = \sum\limits_{m=0}^{n-1}{\sum\limits_{k=1}^\infty k \left(\frac{m}{n}\right)^{k-1} \frac{n - m}{n}}$$

Now thanks to some help from [Wolfram Alpha](http://www.wolframalpha.com/), this formula is equal to:[^1]

[^1]: I couldn't figure out how to get such a nice result directly, without the help of WA, but if anyone else can, let me know!

$$
\begin{equation}%\tag{Exp-simp}
E(n) = n \sum\limits_{i=1}^{n}{\frac{1}{i}}
\label{eq:exp-simp}
\end{equation}
$$

The summation above happens to be the \\(n\\)th [harmonic number](http://en.wikipedia.org/wiki/Harmonic_number), and so in the limit, the whole expression is approximately equal to:

$$E(n) \approx n (\gamma + \ln(n))$$

where \\(\gamma\\) is the [Euler-Mascheroni constant](http://en.wikipedia.org/wiki/Euler%E2%80%93Mascheroni_constant).
This puts the average case in \\(\mathcal{O}(n\ln(n))\\).
In the worst case, there are infinite collisions, so the algorithm never terminates.


### Fisher-Yates

In Fisher-Yates, the answer is simple.
<code>rand_n()</code> is called \\(n - 1\\) times, so in both the average and worst cases the number of calls is in \\(\mathcal{O}(n)\\).

### Summary

<figure>
<table>
	<tr>
		<th>Algorithm</th>
		<th>Average Case</th>
		<th>Worst Case</th>
	</tr>
	<tr>
		<td>Brute-Force</td>
		<td>\(\mathcal{O}(n\ln(n))\)</td>
		<td>Unbounded</td>
	</tr>
	<tr>
		<td>Fisher-Yates</td>
		<td>\(\mathcal{O}(n)\)</td>
		<td>\(\mathcal{O}(n)\)</td>
	</tr>
</table>
<figcaption>Summary of calls to <code>rand_n()</code>.</figcaption>
</figure>

## Benchmark
The theory's nice, but how does this work out in practice?

### Average Case
First, I had both algorithms shuffle a smattering of deck sizes 10,000 times each.
Here's how long those shuffles took on average:

<div id="shuffle-num-time-graph" class="graph"><div class="graph-warning"></div></div>

The brute-force algorithm is definitely slower, but how much slower?

<div id="shuffle-num-calls-graph" class="graph"><div class="graph-warning"></div></div>

This graph shows the ratio of the brute-force time over the Fisher-Yates time.
You can see the logarithmic difference pretty clearly.

### Worst Case
To look at worst cases, I ran the brute-force algorithm over a 52-card deck 5,000,000 times.
The graph below shows how the probability \\(y\\) that a shuffle finished in exactly \\(x\\) calls.

<div id="shuffle-num-calls-histogram" class="graph"><div class="graph-warning"></div></div>

The mean (236.08) is close to the expected value (235.98, from Eq. \\(\eqref{eq:exp-simp}\\) above).
However, it's clear that there's a big spread.
One of the runs took 953 calls, or more than 4 times the expected number.
Assuming a real random number generator, then for any \\(k\\) you choose, if you run the algorithm enough times, you would eventually find an execution calling <code>rand_n()</code> more than \\(k\\) times.
This is clearly not an algorithm suitable for real-time purposes.

## Conclusion
Okay, so the brute-force algorithm isn't great.
It might not terminate, it runs significantly slower than the Fisher-Yates algorithm, and it's not a whole lot simpler.
But it's also not horrible---for deck sizes smaller than 70, it's less than 5 times slower.
This really surprised me.
Naively, I thought that due to the random nature of the algorithm, the runtime might have an exponential or even factorial component.
There's probably very little reason[^2] to use the brute-force algorithm over Fisher-Yates, but \\(\mathcal{O}(n\ln(n))\\) ain't that bad.

[^2]: BF does perform half as many writes as FY, so perhaps if writes are *really* expensive...
