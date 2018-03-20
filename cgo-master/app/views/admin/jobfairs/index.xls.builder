models_to_excel(xml, @jobfairs, {
    :include => ["id", "category", "sponsor", "date", "start_time", "end_time", 
		 "fees", "city", "location", "location_url", 
		 "recommended_hotel", "recommended_hotel_url", 
		 "security_clearance_required", "created_at", "updated_at"]
})