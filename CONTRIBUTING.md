Contributors are welcome! I'm a big believer in [the GitHub flow](http://guides.github.com/overviews/flow/), and the [Atom package contribution guide](https://atom.io/docs/latest/contributing) is a solid resource, too.

Here's the process in a nutshell:

 1. Fork it. :fork_and_knife:
 2. Run `apm develop merge-conflicts` from your terminal to get a clone of this repo. By default, this will end up in a subdirectory of `${HOME}/github`, but you can customize it by setting `${ATOM_REPOS_HOME}`.
 3. Fix up your remotes. The convention is to have `origin` pointing to your fork and `upstream` pointing to this repo.

 Assuming you set up your username using [the local GitHub Config Convention](https://github.com/blog/180-local-github-config)

 ```bash
 $ git config --global github.user your_username
 ```

 You can set your remotes up with something like:

   ```bash
   cd ${ATOM_REPOS_HOME:-~/github}/merge-conflicts
   git remote rename origin upstream
   git remote add origin git@github.com:`git config github.user`/merge-conflicts.git
   ```

 4. Create a branch and work on your awesome bug or feature! Commit often and consider opening a pull request *before* you're done. Follow the style and conventions of existing code and be sure to write specs!
 5. Get it merged. Profit :dollar:
