require 'jira'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering the information below.'

    FIELDS = {
        base_url: {
            :label => 'Jira URL without trailing slash',
            :placeholder => 'https://jira.example.org'
        },
        context_path: {
            :optional => true,
            :label => 'Context Path (Just "/" if empty otherwise with leading slash)',
            :placeholder => "/jira"
        },
        username: {
            :label => 'Username',
            :placeholder => 'johndoe'
        },
        password: {
            :label => 'Password',
            :placeholder => 'p@assW0rd'
        },
        project_id: {
            :label => 'Project Key',
            :placeholder => 'The project Key where the issue will be created'
        },
        issue_priority: {
            :label => 'Priority',
            :placeholder => 'Normal'
        }
    }

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def self.body_template
      @body_template ||= ERB.new(File.read(
        File.join(
          ErrbitJiraPlugin.root, 'views', 'jira_issues_body.txt.erb'
        )
      ))
    end


  # Icons to display during user interactions with this issue tracker. This
  # method should return a hash of two-tuples, the key names being 'create',
  # 'goto', and 'inactive'. The two-tuples should contain the icon media type
  # and the binary icon data.
  def self.icons
    @icons ||= {
      create: [ 'image/png', File.read('app/assets/images/jira_create.png') ],
      goto: [ 'image/png', File.read('app/assets/images/jira_goto.png') ],
      inactive: [ 'image/png', File.read('app/assets/images/jira_inactive.png') ],
    }
  end

    def configured?
      options['project_id'].present?
    end

    def errors
      errors = []
      if self.class.fields.detect {|f| options[f[0]].blank? && !f[1][:optional]}
        errors << [:base, 'You must specify all non optional values!']
      end
      errors
    end

    def comments_allowed?
      false
    end

    def client
      opts = {
        :username => options['username'],
        :password => options['password'],
        :site => options['base_url'],
        :auth_type => :basic,
	:use_ssl => false,
        :context_path => (options['context_path'] == '/') ? options['context_path'] = '' : options['context_path']
      }
      JIRA::Client.new(opts)
    end

    def create_issue(title, body, user: {})
      begin
puts title
puts body
        issue = {"fields"=>{"summary"=>title, "description"=>body, "project"=>{"key"=>options['project_id']},"issuetype"=>{"name"=>"Bug"},"priority"=>{"name"=>options['issue_priority']}}}
        
        issue_build = client.Issue.build
        issue_build.save(issue)
        jira_url(issue_build.key)
      rescue JIRA::HTTPError
        raise ErrbitJiraPlugin::IssueError, "Could not create an issue with Jira.  Please check your credentials."
      end
    end

    def jira_url(key)
      "#{options['base_url']}#{ctx_path}/browse/#{key}"
    end

    def ctx_path
      (options['context_path'] == '') ? '/' : options['context_path']
    end

    def url
      options['base_url']
    end
  end
end
