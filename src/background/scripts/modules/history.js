var History = (function() {

	function search(msg) {
    var tab     = arguments[arguments.length-1],index;
    var keyword = msg.keyword;

    chrome.history.search({text: keyword}, function(historys) {
      Post(tab, { action: "Dialog.draw", urls: historys, keyword: keyword });
    })
	}
  // dateAdded: 1292228084838
  // id: "6"
  // index: 3
  // parentId: "1"
  // title: "Google"
  // url: "http://www.google.com/"

  return { search : search }
})();