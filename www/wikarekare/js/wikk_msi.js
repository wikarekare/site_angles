// Fetch MSI Antenna pattern files from the server (in JSON format)
var wikk_msi = ( function() {
  var read_local_completion = null;
  var list_antenna_local_completion = null;
  var pattern = null;
  var antenna = null;

  function fetch_msi_error(jqXHR, textStatus, errorMessage) {   // Called on failure
    pattern = null;
  }

  function fetch_msi_completion(data) {  // Called after we have received and processed data
    if(read_local_completion != null) {
      read_local_completion(pattern);
    }
  }

  function fetch_msi_callback(data) { // Called when data is returned
    if(data != null && data.result != null) {
      pattern = data.result;
    } else {
      pattern = null;
    }
  }

  // WIKK RPC call to fetch json formatted Antenna msi files Antenna_msi::read
  function fetch_msi(antenna, local_completion, delay) {
    if(delay == null) delay = 0;
    read_local_completion = local_completion; // Call this, after getting the data.

    var args = {
      "method": "Antenna_msi.read",
      "kwparams": {
        "select_on": { antenna: antenna },         // Default select to get all
        "orderby": null,
        "set": null,
        "result": [ ]             // Accept what is sent
      },
      "version": 1.1
    }

    url = "/ruby/rpc.rbx"
    wikk_ajax.delayed_ajax_post_call(url, args, fetch_msi_callback, fetch_msi_error, fetch_msi_completion, 'json', true, delay);
    return false;
  }

  function get_pattern() { // Getter. Unlikely to be called.
    return pattern;
  }

  // antenna of antenna files
  function list_antenna_error(jqXHR, textStatus, errorMessage) {   // Called on failure
    antenna = null;
  }

  function list_antenna_completion(data) {  // Called after we have received and processed data
    if(list_antenna_local_completion != null) {
      list_antenna_local_completion(antenna);
    }
  }

  function list_antenna_callback(data) { // Called when data is returned
    if(data != null && data.result != null) {
      antenna = data.result.antenna;
    } else {
      antenna = null;
    }
  }

  function list_antenna(local_completion, delay) {
    if(delay == null) delay = 0;
    list_antenna_local_completion = local_completion; // Call this, after getting the data.

    var args = {
      "method": "Antenna_msi.antenna",
      "kwparams": {
        "select_on": { },
        "orderby": null,
        "set": null,
        "result": [ ]             // Accept what is sent
      },
      "version": 1.1
    }

    url = "/ruby/rpc.rbx"
    wikk_ajax.delayed_ajax_post_call(url, args, list_antenna_callback, list_antenna_error, list_antenna_completion, 'json', true, delay);
    return false;
  }

  function get_antenna() { // Getter. Unlikely to be called.
    return antenna;
  }


  //return a hash of key: function pairs, with the key being the same name as the function.
  //Hence call with wikk_signal_comms.function_name()
  return {
    fetch_msi: fetch_msi,
    get_pattern: get_pattern,
    list_antenna: list_antenna,
    get_antenna: get_antenna
  };
})();
