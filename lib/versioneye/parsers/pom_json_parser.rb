require 'versioneye/parsers/common_parser'

class PomJsonParser < CommonParser


  def parse(url)
    return nil if url.nil? || url.empty?

    response = self.fetch_response( url )
    parse_content response.body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( content )
    pom_json = JSON.parse( content )
    return nil if pom_json.nil?

    project = Project.new({:project_type => Project::A_TYPE_MAVEN2, :language => Product::A_LANGUAGE_JAVA })
    pom_json['dependencies'].each do |json_dep|
      version     = json_dep['version']
      name        = json_dep['name']
      spliti      = name.split(':')
      group_id    = spliti[0]
      artifact_id = spliti[1]
      dependency  = init_dependency(name, group_id, artifact_id, version)
      product     = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id, Product::A_LANGUAGE_JAVA )
      dependency.prod_key     = product.prod_key if product
      project.unknown_number += 1 if product.nil?
      project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
      project.projectdependencies.push(dependency)
    end
    project.dep_number = project.dependencies.size
    project.name = pom_json['name']
    project
  end


  def init_dependency name, group_id, artifact_id, version
    dependency             = Projectdependency.new
    dependency.language    = Product::A_LANGUAGE_JAVA
    dependency.name        = name
    dependency.group_id    = group_id
    dependency.artifact_id = artifact_id
    dependency.version_requested = version
    dependency
  end

end
