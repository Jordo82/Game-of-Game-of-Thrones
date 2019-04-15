Game of Game of Thrones
================
Jordan Upton

This month sees the return of HBO's hit series Game of Thrones for it's final six episodes. To celebrate the finale, my office started a GoT betting pool. It's all the fun of March Madness, but with a topic I actually know!

The rules of the game were taken from [this Reddit post](https://www.reddit.com/r/gameofthrones/comments/akq0rm/spoilers_game_of_thrones_season_8_deadpool_is/). The primary goal of the game is to guess which of the 24 characters shown will be dead or alive by the end of the series (with bonus points if you guess the episode they die and whether or not they become a wight).

[<img src="pics/all.png" alt="no caption" width="500" />](https://www.reddit.com/r/gameofthrones/comments/akq0rm/spoilers_game_of_thrones_season_8_deadpool_is/)

A total of 36 people entered into the pool, and with 24 characters per entry, that's 864 total guesses for who will live and who will die. That's a great sample size that allows us to see whether there's any patterns in people's choices.

Summary metrics
---------------

I began by reading the entries in R and computing some simple summary metrics. For starters, what proportion of entries picked each character to die?

<center>
<img src="plots/Death%20Rate.png" alt="Death Rate by Character" width="750" />

</center>
Across all of the entries, people picked characters to die at a rate of 57.6%, or just shy of 14 out of the 24 characters being killed off. Most expect Samwall Tarly to make it through unscathed, but not a single person thinks Cersei is still going to be around by the end.

Similarity of Picks
-------------------

Looking over the entries, I noticed a lot of variations in people's choices. Some thought Jon Snow would live while Daenerys would die, some thought the opposite. Other than Cersei's death, there was no concensus among the entries.

I wanted to visualize how similar or different each of the entries were from each other. Given that we have 24 different characters, I'd need a 24-dimensional plot in order to make the visualization accurate. I don't even have a 3d printer, so we're going to turn to [Principal Component Analysis (PCA)](https://en.wikipedia.org/wiki/Principal_component_analysis) instead. PCA looks for correlations in the data and uses those to reduce the dimensionality still keeping some of the "signal". Think of it like a shadow: a shadow doesn't give us the full picture of whatever cast it, but it can be used to make an informed estimate. Let's look at the two-dimensional shadow of our 24-dimensional data.

<center>
<img src="plots/Pick%20Similarity%20No%20Cluster.png" alt="no cap" width="750" />

</center>
The distance between the names tell you generally how similar or different the entires were from each other. Some entries immediately jump out, such as Joe Bucolo who doesn't even watch the show! Entires closer to the origin of the plot are closer to the overall average of all entries. Yours truly is closest to average, I think the kids call that being "basic"?

Clusters of Entries
-------------------

It's hard to think in 24 dimensions, so let's try to simplify things a little further. What if we wanted to create distinct groups of entries, like "Team Stark" or "Team Gendry"? You could do this with hierarchical rules, such as everyone who picked Bran to live and Jon to die is on one "team", but a couple of problems quickly emerge. Either you need a **lot** of teams to account for all the variation in selections, or you have to simplify the criteria for teams so much that there's ultimately not a lot of difference between the entries in each team.

[Cluster Analysis](https://en.wikipedia.org/wiki/Cluster_analysis) was built to solve these types of problems. It will find teams or "clusters" of entries that are internally homogeneous and externally heterogeneous. That is, entries within the same cluster will be mostly similar, while the average entry in each cluster is as different as possible. Let's use cluster analysis to create four distinct groups of entries.

<center>
<img src="plots/Pick%20Similarity.png" alt="no cap" width="750" />

</center>
In general, entries that are displayed close together on the plot tend to be in the same cluster as we might expect. However, there are some cases where an entry appears to be "invading" another cluster's territory. This can happen because the cluster analysis is using the full 24 dimensions to determine an entry's cluster, while the plot is limited to our 2 dimensional "shadow" of the data.

These four clusters represent very different visions of how the final episodes will play out. As the deadpool progresses, I suspect that most of the leaders will come from a single one of these clusters with the winner being determined by bonus points. In order to get a better sense of what makes the clusters different, let's examine each cluster's most distinctive picks on who will live and die; i.e. which picks were the most different from the overall average.

<center>
<img src="plots/Cluster%20Distinctiveness.png" alt="no cap" width="500" />

</center>
-   **Cluster 1:** some real hot takes here. There's only three entries in this cluster, so the data is pretty thin. This is also the cluster that's most different from the overall average. Dany & Tyrion die but The Mountain lives? Nice try Cluster 1, thanks for the $$$!

-   **Cluster 2:** if I were still in Marketing, I might call this the "girl power" cluster. Very bold picks to have the warriors Yara and Brienne live while Bran "Don't call me Bran" Stark gets the axe.

-   **Cluster 3:** this cluster is closest to the overall average of all entries, perhaps that gives it the best chance of producing a winner? A version of Westeros where Arya & Jon both die would be fitting for a show like this.

-   **Cluster 4:** a bit of a mixed bag here. Beric Dondarrion makes a surprising appearance to stay alive, but that's because only a single entry had him living and that entry is in this cluster. Overall, this cluster is not too different from average.

Next Steps
----------

I may revist this as the season unfolds to see how the points get distributed; what were the most obvious "free points" and what did nobody see coming? There's also an interesting(?) discussion on maximizing the expected value of picks, given that you can get up to 3 points for picking someone as dead vs only a single point for alive.
