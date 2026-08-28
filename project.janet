(declare-project
  :name "smb-janet"
  :description "Behavior-preserving Janet-native Super Mario Bros. reconstruction"
  :version "0.0.0"
  :dependencies [{:url "https://github.com/janet-lang/jaylib.git"
                  :tag "d7da7f14815e5ac70d02d6a942d1ae5adb04cb12"}
                 {:url "https://github.com/janet-lang/spork.git"
                  :tag "3918802d6b79848a3dba113b1fe2ee1a8f7b667b"}])

(declare-source
  :prefix "smb"
  :source ["src/smb"])
