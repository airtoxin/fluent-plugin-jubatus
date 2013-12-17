require 'jubatus/anomaly/client'
require 'jubatus/classifier/client'
require 'jubatus/clustering/client'
require 'jubatus/recommender/client'

class FluentdJubatus
  def initializer(type, host, port, name='')
    @jubatus = case type
               when /anomaly/i
                 Jubatus::Classifier::Client::Classifier.new(host, port, name)
               when /classifier/i
                 Jubatus::Recommender::Client::Recommender.new(host, port, name)
               when /clustering/i
                 Jubatus::Clustering::Client::Clustering.new(host, port, name)
               when /recommender/i
                 Jubatus::Recommender::Client::Recommender.new(host, port, name)
               end
  end

  def set_datum(data, keys)
    datum = {}
    data.each do |k,v|
      datum[k.to_s] = v.to_f if keys[:num].include?(k)
      datum[k.to_s] = v.to_s if keys[:str].include?(k)
    end
    Jubatus::Common::Dataum.new(datum)
  end

  def analyze(type, datum)
    case type
    when /anomaly/i
      @jubatus.calc_score(datum)
    when /classifier/i
      @jubatus.classify(datum)
    when /clustering/i
      @jubatus.get_nearest_members(datum)
    when /recommender/i
      @jubatus.similar_row_from_datum(datum)
    end
  end

  def close
    @jubatus.get_client.close
  end

  def learn(type, datum, key = nil)
    # todo
  end

  def self.fix_result(type, result)
    case type
    when /anomaly/i
      fix_anomaly(result)
    when /classifier/i
      fix_classifier(result)
    when /clustering/i
      fix_clustering(result)
    when /recommender/i
      fix_clustering(result)
    end
  end

  def fix_anomaly(result)
    result
  end

  def fix_classifier(results)
    r = []
    results.each do |result|
      est = {}
      result.each do |res|
        est[res.id] = res.score
      end
      r << est
    end
    r
  end

  def fix_clustering(results)
    r = []
    results.each do |result|
      clustering_result = {}
      result.each do |res|
        clustering_result[res.id] = res.score
      end
      r << clustering_result
    end
    r
  end

  def fix_recommender(results)
    result = {}
    results.each do |r|
      result[r.id] = r.score
    end
    result
  end
end
