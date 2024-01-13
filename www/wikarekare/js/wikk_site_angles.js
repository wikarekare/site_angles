var wikk_site_angles = ( function() {
  var no_site_vectors = {"None": { distance: 0, min_dec: 0, max_dec: 0, max_angle: 0, best_angle: 0, data: [], data2: [] }};
  var dist_site_vectors = no_site_vectors;
  var registered_local_completion = null;

  function site_angles_error(jqXHR, textStatus, errorMessage) {   // Called on failure
  }

  function site_angles_completion(data) {  // Called after we have received and processed data
    if(registered_local_completion != null) {
      registered_local_completion(dist_site_vectors);
    }
  }

  function site_angles_callback(data) { // Called when data is returned
    if(data != null && data.result != null) {
      dist_site_vectors = data.result;
    } else {
      dist_site_vectors = no_site_vectors;
    }
  }

  function get_dist_site_vectors() { // Getter
    return dist_site_vectors;
  }

  // WIKK RPC call to class Site_Angles::read
  function fetch_site_angles(local_completion, delay) {
    if(delay == null) delay = 0;
    registered_local_completion = local_completion; // Call this, after getting the data.

    var args = {
      "method": "Site_Angles.read",
      "params": {
        "select_on": { },         // Default select to get all
        "orderby": null,
        "set": null,
        "result": [ ]             // Accept what is sent
      },
      "id": Date.getTime(),
      "jsonrpc": 2.0
    }

    url = RPC
    wikk_ajax.delayed_ajax_post_call(url, args, site_angles_callback, site_angles_error, site_angles_completion, 'json', true, delay);
    return false;
  }

  //return a hash of key: function pairs, with the key being the same name as the function.
  //Hence call with wikk_signal_comms.function_name()
  return {
    fetch_site_angles: fetch_site_angles,
    get_dist_site_vectors: get_dist_site_vectors
  };
})();
