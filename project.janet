(declare-project
  :name "smb-janet"
  :description "Behavior-preserving Janet-native Super Mario Bros. reconstruction"
  :version "0.0.0"
  :dependencies [{:url "https://github.com/jhaton/janet-raylib.git"
                  :tag "3217be8cf4ead11c638c300eb0b24337cf95cd6f"}
                 {:url "https://github.com/janet-lang/spork.git"
                  :tag "3918802d6b79848a3dba113b1fe2ee1a8f7b667b"}])

(declare-source
  :prefix "smb"
  :source ["src/smb"])
