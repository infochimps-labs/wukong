## Example: Git Subtree 

There are 50+ subprojects. Each supports the following

* create the subproject's repo on github and set its metadata
* clone the subproject to a local copy
* in the main repo, split 



The workflow for each is as follows:

> 
> The push workflow is
> 
> * assumes: the subproject is cloned the right place on disk
> * assumes: the main repo has split its changes into a branch named for the subproject
> * in subproject, pull in changes from its origin/master
> * in subproject, pull in changes from main repo (`git pull {main_repo_dir}/.git br-foo:master`). Will halt if there are conflicts.
> * push from subproject to its origin/master
> 
> The pull workflow goes analogously.
> 
> To create the subproject's github repo,
> 
> * use the github API to create the repo; swallow 
> * use the github API to set permissions, write name, etc.
>
> To split out changes from the main repo into a subproject-only branch
>
> * assumes: the main repo is on its major code branch
> * in main repo, select only the tree's changes into a subtree-only branch `br-foo` (`git subtree split -b br-foo`)
> * 

The master flow takes the 




See Also

* https://github.com/cypher/thor-git/blob/master/git.thor
