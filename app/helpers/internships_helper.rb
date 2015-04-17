module InternshipsHelper
  def set_internship_background(rating)
    if rating
      if rating.interest == "1"
        'internship-high-interest'
      elsif rating.interest == "2"
        'internship-medium-interest'
      elsif rating.interest == "3"
        'internship-low-interest'
      end
    else
      nil
    end
  end
end
