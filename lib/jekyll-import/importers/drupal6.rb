require "jekyll-import/importers/drupal_common"

module JekyllImport
  module Importers
    class Drupal6 < Importer
      include DrupalCommon
      extend DrupalCommon::ClassMethods

      def self.build_query(prefix, types, engine)
        types = types.join("' OR n.type = '")
        types = "n.type = '#{types}'"

        query = <<EOS
                SELECT n.nid,
                       n.title,
                       nr.body,
                       nr.teaser,
                       n.created,
                       n.status,
                       n.type,
                       (SELECT GROUP_CONCAT( td.name SEPARATOR '|' ) FROM term_data td, term_node tn WHERE tn.tid = td.tid AND tn.nid = n.nid) AS 'tags',
                       (SELECT GROUP_CONCAT( af.filepath SEPARATOR '|' ) FROM audio_file af WHERE af.vid = n.nid) AS 'audiofiles',
                       (SELECT GROUP_CONCAT( fl.filepath SEPARATOR '|' ) FROM files fl WHERE fl.nid = n.nid) AS 'files'
                FROM #{prefix}node_revisions AS nr,
                     #{prefix}node AS n
                WHERE (#{types})
                  AND n.vid = nr.vid
                GROUP BY n.nid
EOS

        return query
      end

      def self.aliases_query(prefix)
        "SELECT src AS source, dst AS alias FROM #{prefix}url_alias WHERE src = ?"
      end

      def self.post_data(sql_post_data)
        content = sql_post_data[:body].to_s
        summary = sql_post_data[:teaser].to_s
        tags = (sql_post_data[:tags] || "").downcase.strip
        files = (sql_post_data[:files] || "").strip.split("|")
        audiofiles = (sql_post_data[:audiofiles] || "").strip.split("|")

        data = {
          "excerpt"    => summary,
          "categories" => tags.split("|"),
        }

        unless files.empty? and audiofiles.empty?
          data["attachments"] = files + audiofiles
        end

        return data, content
      end
    end
  end
end
