model model3

global{	
	//importation de mon modele dans GAMA
	file shape_file_surfacee<- file("../includes/Surface.shp");
	file shape_file_parking<- file("../includes/parking.shp");
	file shape_file_routes<- file("../includes/Chemin.shp");
	geometry shape <- envelope(shape_file_surfacee);
	graph graph_chemin;
	
	//Definition des voitures avec des tailles differentes conpris entre 10 et 20 mm
	int nbres_voitures<-1;
	
	//parametre sur la gestion de la voiture
	float vitesse_min<-1.0 #km / #h;
	float vitesse_max<-3.0 #km / #h;

	//Point creation Voitures Exterieures
	point local_ext<- rnd({74.0,2.0},{-135.0,-5.0});
	//Point Agent_entree
	point localisation<-{83.55,81.32};
	//Point Parking 1
	point local_sortie<-{3.14,449.72};
	float intensite<- 60 #s;
		
	init{	
		create surface from:shape_file_surfacee;	
		create parking from:shape_file_parking  with: [type::string(read ("NATURE"))];	
		create routes from:shape_file_routes;
	 	graph_chemin<-as_edge_graph(routes);
	 	int duree<-20;	      
	    	
	   //creation agent qui oriente les vehicules		   
	   create porte_entree number:1{
			location<-localisation;	
		}
		//creation point de sortie pour les vehicules
		create porte_sortie number:1{
			location<-local_sortie;
		}
     }
//generer les vehicules apres chaque 30 secondes
reflex creer_voiture when: every(intensite)
	    {
	    	 create voiture number: nbres_voitures {	    	
			 speed<- vitesse_min + rnd(vitesse_max - vitesse_min);
			 //routes rt<- one_of(routes);
			 objective<- "Parquer";		
			 location<-local_ext-2+rnd(local_ext);				   
	       }
	    }
}

species surface
{    rgb color<- #gray;
	 aspect base
	 {
	 	draw shape color:color;
	 }
}

species routes
{	
	aspect base
	{
		draw shape color:color;
	}
}
species voiture skills:[moving]
{
	rgb color<- #green;
	int size<-30+rnd(15);
	string objective<-"Partir";
	float montant_paye;
	float duree_stationnement<-0.0;
	float sueil<-100.0+rnd(30.0);
	
    point the_target_sortie<-local_sortie;
    point the_target<-localisation;
    point the_target_parking<-point(one_of(Allparking));
   
    list<voiture> Allvoiture<- voiture where(location!=nil);
    list<parking> Allparking <- parking where(location!=nil);  
	
	//Recupere le nombre des parking existants
	int nbres_parking_dispo<-int(parking(length([Allparking])));	
	//nombres des voitures crees	
	int nbres_voitures_cree<-int(voiture(length([Allvoiture])));
	
	bool voitgarer<-false;
	bool voitsortie<-false;
	
	aspect base
	{		
		draw square(size) color:color;				
	}
	//Reflex qui envoit les vehicules vers  le point d'entree
	reflex move when: the_target !=nil
	{
		do goto target:the_target speed:5 #s;	
		if location=the_target
		{
            the_target <- nil ;
        }    
	}
	//Reflex qui envoit les vehicules vers le parking de son choix
	reflex deplacer_parking when: the_target=nil{
		do action: goto target: the_target_parking  speed:80.0 #s;	
		if location=the_target_parking
		{
		  the_target_parking<-nil;
		  objective<-"garer";
		  voitgarer<-true;
	      duree_stationnement<-duree_stationnement-4;
		}
	}
	//Reflex qui envoit les vehivules vers le point de sortie	
	reflex sortir_parking when: the_target_parking=nil
	{ 
		duree_stationnement<-duree_stationnement+1;		
		if(duree_stationnement>sueil)
		{
			do action: goto target: the_target_sortie speed:2.0;
	        voitsortie<-true;
	     
	     //montant payer a la sortie par chaque vehicule
	        montant_paye<- size * duree_stationnement;	     
	     if location=the_target_sortie
	     {
	     	do action:die;
	     	write(montant_paye);
	     }		
		}		 
	}	
}

species porte_entree {
	rgb color<- #red;
	int size<-15 ;

aspect base
    {
		draw circle(size) color:color;
	} 
} 

species parking{	
	rgb color<- #red;	
	
	aspect base
	{
		draw shape color:color;
	}	
}

species porte_sortie{
	
	rgb color<- #yellow;
	float size<-15.0;
	
aspect base {
		draw circle(size);
	}
}

experiment model3 type:gui
{
	parameter "nombre des vehicules:" var:nbres_voitures category:"Voitures";
	parameter "Intensite des vehicules" var:intensite category:"voitures";
	
	output{		
		display output type:opengl
		{
		species surface aspect:base;
		species parking aspect:base;
		species routes aspect:base;
		species voiture aspect:base;
		species porte_entree aspect:base;
		species porte_sortie aspect:base;		
		}
		
		display chart_montantPaye refresh:every(intensite){
			chart "Montant revenu par heure" type: series size: {1, 0.5} position:{0, 0}
			{
				data "Montant dispo" value:voiture count(each.montant_paye!=nil) color:#red;
			}
		}
				
	}	
}


