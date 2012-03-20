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
    chain(repo_name) do

      remote_repo = github_repo("repo_name") do
        update
        account_name  Settings.github_acct
        description   "Chef cookbook for #{repo_name} from the Ironfan cookbook collection"
      end

      solo_checkout = git_checkout(remote_repo.git_url) do
        directory   [:solo_root, repo_name]
        branch      :master
      end

      script do
      end

      #
      # subtree:hadoop:push
      chain(:push) do
        updates  remote_repo
        creates  solo_checkout
        pulls    solo_checkout, remote_repo
        runs     split_subtree
        pulls    solo_checkout, split_subtree
        pushes   solo_checkout, remote_repo
        add_to chain('subtree:push') # subtree:push will invoke this at most once
      end

      chain
    end

  end
end
