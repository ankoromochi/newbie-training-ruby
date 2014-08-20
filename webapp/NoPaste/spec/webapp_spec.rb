require 'spec_helper'

describe 'top' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'response collectly' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.header['Content-Type']).to eq('text/html;charset=utf-8')

    expect(last_response.body).to have_tag('title', text: 'NoPaste')
    expect(last_response.body).to have_tag('div.hero-unit p a',
                                           text: 'Please sign in',
                                           with: {href: '/signin'})
  end
end

describe 'signup' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'ok' do
    get '/signup'
    expect(last_response.status).to eq(200)
    expect(last_response.header['Content-Type']).to eq('text/html;charset=utf-8')

    body = last_response.body
    expect(body).to have_tag('h2.form-signin-heading', text: 'Sign up now!')

    expect(body).to have_tag('form.form-signin', with: {method: 'post', action: '/signup'})
    expect(body).to have_tag("form.form-signin input[name='username']")
    expect(body).to have_tag("form.form-signin input[name='password']")
    expect(body).to have_tag("form.form-signin input[name='password_confirm']")

    doc = Nokogiri::HTML(body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")
    expect(hidden).to be_present
    expect(hidden.attribute('value')).to be_present

    username = "test#{$$}"
    password = "pass#{$$}"
    post '/signup', username:         username,
                    password:         password,
                    password_confirm: password,
                    csrf_token:       hidden.attribute('value')

    expect(last_response.status).to eq(302)
    location = last_response.header['Location']
    expect(location).to eq('http://example.org/')

    get location
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('p.navbar-text', text: /Logged in as #{Regexp.escape(username)}/)
  end

  it 'csrf error' do
    get '/signup'
    expect(last_response.status).to eq(200)
    doc = Nokogiri::HTML(last_response.body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")
    expect(hidden).to be_present
    expect(hidden.attribute('value')).to be_present

    username = "test#{$$}"
    password = "pass#{$$}"
    post '/signup', username:         username,
                    password:         password,
                    password_confirm: password

    expect(last_response.status).to eq(403)
  end

  it 'validation error' do
    get '/signup'
    expect(last_response.status).to eq(200)
    doc = Nokogiri::HTML(last_response.body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")
    expect(hidden).to be_present
    expect(hidden.attribute('value')).to be_present

    username = "test#{$$}"
    password = "pass#{$$}"
    post '/signup', username:         username,
                    password:         password,
                    password_confirm: password,
                    csrf_token:       hidden.attribute('value')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('div.error span.help-inline', text: /Already exists/)

    username = "xxxx#{$$}"
    password = "pass#{$$}"
    post '/signup', username:         username,
                    password:         password,
                    password_confirm: "#{password}xxx",
                    csrf_token:       hidden.attribute('value')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('div.error span.help-inline', text: /Confirm mismatch/)
  end
end

describe 'signout' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'ok' do
    get '/signout'

    expect(last_response.status).to eq(302)
    location = last_response.header['Location']
    expect(location).to eq('http://example.org/')

    get location
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('p.navbar-text', text: /Sign in/)
  end
end

describe 'signin' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  it 'ok' do
    get '/signin'
    expect(last_response.status).to eq(200)
    body = last_response.body
    expect(body).to have_tag('form.form-signin', with: {method: 'post', action: '/signin'})
    expect(body).to have_tag("form.form-signin input[name='username']")
    expect(body).to have_tag("form.form-signin input[name='password']")
    doc = Nokogiri::HTML(body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")
    expect(hidden).to be_present
    expect(hidden.attribute('value')).to be_present

    username = "test#{$$}"
    password = "pass#{$$}"

    post '/signin', username:   username,
                    password:   password,
                    csrf_token: hidden.attribute('value')
    expect(last_response.status).to eq(302)
    expect(last_response.header['Location']).to eq('http://example.org/')

    get last_response.header['Location']
    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('p.navbar-text', text: /Logged in as #{Regexp.escape(username)}/)
  end

  it 'failed' do
    get '/signin'
    expect(last_response.status).to eq(200)
    doc = Nokogiri::HTML(last_response.body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")
    expect(hidden).to be_present
    expect(hidden.attribute('value')).to be_present

    username = "test#{$$}"
    post '/signin', username:   username,
                    password:   'xxxx',
                    csrf_token: hidden.attribute('value')

    expect(last_response.status).to eq(200)
    expect(last_response.body).to have_tag('div.error span.help-inline', text: /FAILED/)
  end
end

describe 'top' do
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  before do
    get '/signin'
    doc = Nokogiri::HTML(last_response.body)
    hidden = doc.css("form.form-signin input[name='csrf_token']")

    post '/signin', username:   "test#{$$}",
                    password:   "pass#{$$}",
                    csrf_token: hidden.attribute('value')
  end

  it 'is logined and has textarea' do
    get '/'
    expect(last_response.body).to have_tag('div.hero-unit form', with: {action: '/post', method: 'post'})
    expect(last_response.body).to have_tag("div.hero-unit form textarea[name='content']")
  end
end
