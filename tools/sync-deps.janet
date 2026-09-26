# Uninstall dependencies whose installed source differs from project.janet.
#
# janet-pm keeps an installed bundle even when project.janet pins a different
# tag or URL ("a conflicting bundle ... is already installed, keeping that one").
# Run this before `janet-pm deps` so pin changes actually take effect.
#
# usage: JANET_PATH=jpm_tree/lib janet tools/sync-deps.janet

(defn- repo-name
  "Repository name without scheme, host, or .git, so SSH and HTTPS URLs match."
  [url]
  (def base (last (string/split "/" (last (string/split ":" url)))))
  (if (string/has-suffix? ".git" base) (string/slice base 0 -5) base))

(defn- pinned-dependencies []
  (def project (find |(and (tuple? $) (= 'declare-project (first $)))
                     (parse-all (slurp "project.janet"))))
  (unless project (error "project.janet has no declare-project form"))
  (get (struct ;(slice project 1)) :dependencies []))

(defn main [&]
  (def pins (tabseq [dep :in (pinned-dependencies)
                     :when (and (dictionary? dep) (dep :url))]
              (repo-name (dep :url)) dep))
  (each name (bundle/list)
    (def source (get (bundle/manifest name) :pm))
    (when-let [pin (and source (= :git (source :type)) (pins (repo-name (source :url))))]
      (unless (and (= (source :url) (pin :url)) (= (source :tag) (pin :tag)))
        (printf "sync-deps: %s installed from %s @ %s, pinned to %s @ %s; uninstalling"
                name (source :url) (source :tag) (pin :url) (pin :tag))
        (bundle/uninstall name)))))
