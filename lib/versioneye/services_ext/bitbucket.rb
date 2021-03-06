require 'oauth'

class Bitbucket < Versioneye::Service


  A_API_V2_PATH = "/api/2.0"
  A_API_V1_PATH = "/api/1.0"
  A_DEFAULT_HEADERS = {"User-Agent" => "Chrome28 (contact@versioneye.com)"}


  def self.consumer_key
   Settings.instance.bitbucket_token
  end


  def self.init_oauth_client
    OAuth::Consumer.new(Settings.instance.bitbucket_token, Settings.instance.bitbucket_secret,
                       site: Settings.instance.bitbucket_base_url,
                       request_token_path: "/api/1.0/oauth/request_token",
                       access_token_path:  "/api/1.0/oauth/access_token",  # "/site/oauth2/access_token",
                       authorize_path:     "/api/1.0/oauth/authenticate")  # "/site/oauth2/authorize"
  end


  def self.request_token(callback_url)
    oauth = init_oauth_client
    oauth.get_request_token(oauth_callback: callback_url)
  end


  # Returns user information for authorized user
  def self.user(token, secret)
    path = "#{A_API_V1_PATH}/user"
    response = get_json(path, token, secret)
    response[:user] if  response.is_a?(Hash)
  end


  # Returns bitbuckets' profile info for username
  def self.user_info(user_name, token, secret)
    return if user_name.to_s.strip.empty?
    path = "#{A_API_V2_PATH}/users/#{user_name}"
    get_json(path, token, secret)
  end


  def self.user_orgs( user )
    path = "#{A_API_V1_PATH}/user/privileges"
    data = get_json(path, user[:bitbucket_token], user[:bitbucket_secret])
    return if data.to_a.empty?
    data[:teams].keys
  end


  def self.user_emails( user )
    path = "#{A_API_V1_PATH}/users/#{user.bitbucket_login}/emails"
    get_json(path, user[:bitbucket_token], user[:bitbucket_secret])
  end


  def self.read_repos(user_name, token, secret)
    path = "#{A_API_V2_PATH}/repositories/#{user_name}"
    repos = []
    while true do
      data = get_json(path, token, secret)
      if data.nil? || data.empty?
        log.error "data is nil for #{path}"
        break
      end

      repos.concat(data[:values]) if data.has_key?(:values)

      break if !data.has_key?(:next) or data[:next].to_s.empty?
      path = data[:next]
    end
    repos
  end


  # Returns all the repo user has at least read access
  # NB! it has own data format and it just used to find out invited projects
  def self.read_repos_v1(token, secret)
    path = "#{A_API_V1_PATH}/user/repositories"
    repos = get_json(path, token, secret)
    if repos.is_a?(Array)
      repos.each {|repo| repo[:full_name] = "#{repo[:owner]}/#{repo[:slug]}" }
    end
    repos
  end


  def self.repo_info(repo_name, token, secret)
    path = "#{A_API_V2_PATH}/repositories/#{repo_name}"
    get_json(path, token, secret)
  end


  def self.repo_branches(repo_name, token, secret)
    path  = "#{A_API_V1_PATH}/repositories/#{repo_name}/branches"
    data = get_json(path, token, secret)
    return if data.nil? or not data.is_a?(Hash)

    branches = []
    data.keys.each do |key|
      branches.push key.to_s
    end
    branches
  end


  def self.repo_project_files(repo_name, token, secret)
    branches = repo_branches(repo_name, token, secret)
    return if branches.to_a.empty?

    files = {}
    branches.each do |branch|
      project_files = project_files_from_branch(repo_name, branch, token, secret)
      branch_name   = encode_db_key(branch)
      files[branch_name] = project_files if project_files
    end
    files
  end


  def self.repo_branch_tree(repo_name, branch, token, secret, directory = '')
    path = "#{A_API_V1_PATH}/repositories/#{repo_name}/src/#{branch}/#{directory}"
    get_json(path, token, secret)
  end


  def self.project_files_from_branch(repo_name, branch, token, secret)
    branch_tree = repo_branch_tree(repo_name, branch, token, secret)
    if branch_tree.nil?
      log.error "Didnt get branch tree for #{repo_name}/#{branch}."
      return
    end

    project_files = branch_tree[:files].keep_if do |file_info|
      ProjectService.type_by_filename(file_info[:path]) != nil
    end

    if !branch_tree[:directories].to_a.empty?
      project_files_recursive repo_name, branch, token, secret, '', branch_tree[:directories], project_files, 0
    end

    project_files.each {|file| file[:uuid] = SecureRandom.hex }
    project_files
  rescue => e
    log.error e.message
    log.error e.backtrace.join('/n')
    nil
  end


  def self.project_files_recursive repo_name, branch, token, secret, path = "", directories = nil, project_files = [], deepnes = 0
    directories.to_a.each do |dir_info|
      tree_path = dir_info
      tree_path = "#{path}/#{dir_info}" if !path.to_s.empty?
      tree_path = tree_path.gsub("//", "/")
      branch_tree = repo_branch_tree(repo_name, branch, token, secret, tree_path)
      next if branch_tree.nil? || branch_tree.empty?

      branch_tree[:files].to_a.each do |file_info|
        project_files << file_info if ProjectService.type_by_filename(file_info[:path]) != nil
      end
      if !branch_tree[:directories].to_a.empty? && deepnes.to_i < 5
        new_path = String.new( branch_tree[:path] )
        deepnes += 1
        project_files_recursive repo_name, branch, token, secret, new_path, branch_tree[:directories], project_files, deepnes
      end
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join('/n')
  end


  def self.fetch_project_file_from_branch(repo_name, branch, filename, token, secret)
    path = "#{A_API_V1_PATH}/repositories/#{repo_name}/raw/#{branch}/#{filename}"
    get_json(path, token, secret, true)
  end


  def self.get_json(path, token, secret, raw = false, params = {}, headers = {})
    url = URI.encode "#{Settings.instance.bitbucket_base_url}#{path}"
    oauth = init_oauth_client
    token_obj = OAuth::AccessToken.new(oauth, token, secret)

    # oauth_params = {consumer: oauth, token: token, request_uri: url}

    request_headers = A_DEFAULT_HEADERS
    request_headers.merge! headers

    response = token_obj.get(path, request_headers)

    # if response.code.to_i != 200
    #   TODO
    # end

    if raw == true
      return response.body
    end

    begin
      return JSON.parse(response.body, symbolize_names: true)
    rescue => e
      log.error e.message
      log.error "Got status: #{response.code} #{response.message} body: #{response.body} for path: #{path}"
      log.error e.backtrace.join("\n")
      return nil
    end
  rescue => e
    log.error "ERROR in get_json for #{path} - #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def self.update_branches repo, token, secret
    repo = repo.deep_symbolize_keys if repo.respond_to? "deep_symbolize_keys"
    fullname = repo[:full_name]
    fullname = repo[:fullname] if fullname.to_s.empty?

    branch_docs = Bitbucket.repo_branches( fullname, token, secret )
    if branch_docs && !branch_docs.empty?
      repo[:branches] = branch_docs
    else
      repo[:branches] = ["master"]
    end
    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    repo[:branches] = ["master"]
    repo
  end


  def self.update_project_files repo, token, secret, try_n = 3
    project_files = nil
    repo = repo.deep_symbolize_keys if repo.respond_to? "deep_symbolize_keys"
    fullname = repo[:full_name]
    fullname = repo[:fullname] if fullname.to_s.empty?

    # Adds project files
    try_n.times do
      project_files = Bitbucket.repo_project_files( fullname, token, secret )
      break unless project_files.nil? or project_files.empty?

      log.info "Trying to read `#{fullname}` again"
      sleep 3
    end

    if project_files.nil?
      msg = "Cant read project files for repo `#{fullname}`. Tried to read #{try_n} ntimes."
      log.error msg
    end

    repo[:project_files] = project_files
    repo
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    repo
  end


  def self.encode_db_key(key_val)
    URI.escape(key_val.to_s, /\.|\$/)
  end


  def self.decode_db_key(key_val)
    URI.unescape key_val.to_s
  end

end
