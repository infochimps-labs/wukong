require 'github_repo'

Settings.define :github_acct, :default => 'infochimps-labs', :description => "Github account to synchronize"

# TODO: should be in Configliere, not Wukong
Wukong.register_path :solo_root, [:scratch_dir, 'repoman/solo']


SUBTREES = {
  'cookbooks/hadoop_cluster' => {},
  'cookbooks/snappy'         => {},
}

Wukong.job :subtree do

  SUBTREES.each do |repo_name, repo_info|
    branch_name = "br-#{repo_name}"
    #
    chain(repo_name) do

      remote_repo = github_repo("repo_name") do
        action        :update
        account_name  Settings.github_acct
        description   "Chef cookbook for #{repo_name} from the Ironfan cookbook collection"
      end

      solo_checkout = git_checkout(remote_repo.git_url) do
        directory   [:solo_root, repo_name]
        branch      :master
      end

      script "git subtree split for #{repo_name}" do
        code    [ "git-subtree", "split", "-P", path, "-b", branch_name ]
        expect  ""
      end

      # subtree:#{repo_name}:push
      chain(:push) do
        does :update, remote_repo
        does :create, solo_checkout
        does :pull,   solo_checkout, remote_repo
        does :run,    split_subtree
        does :pull,   solo_checkout, split_subtree
        does :push,   solo_checkout, remote_repo

        # subtree:push will invoke this at most once
        chain('subtree:push') << self
      end

      chain
    end

  end
end
