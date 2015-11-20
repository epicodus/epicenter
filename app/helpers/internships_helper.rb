module InternshipsHelper
  def set_internship_background(rating)
    if rating
      if rating.interest == "1"
        'bg-success'
      elsif rating.interest == "2"
        'bg-warning'
      elsif rating.interest == "3"
        'bg-danger'
      end
    else
      nil
    end
  end
end
